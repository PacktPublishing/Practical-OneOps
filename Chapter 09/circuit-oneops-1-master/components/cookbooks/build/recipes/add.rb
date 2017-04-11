require 'json'

STDOUT.sync = true

# needed for git on 10.04
if node.platform_version == "10.04"   
  Chef::Log.info("adding ppa:git-core/ppa for 10.04")
  # add-apt-repository is in python-software-properties
  bash "update_repos" do
    code <<-EOH
      apt-get -y install python-software-properties
      add-apt-repository ppa:git-core/ppa
      apt-get -y update
    EOH
  end
end


pkgs = [ "git", "git-core", "subversion" ]


pkgs.each do |pkg|
   
   if (node.platform == "centos" && node.platform_version == "5.8") &&
      ( pkg == "git" || pkg == "git-core" )
    
      Chef::Log.info("no git package on centos 5.8")      

    else
      package pkg do
          action :install
      end
   end
   
end

# centos 5.8 git
if node.platform == "centos" && node.platform_version == "5.8"
  remote_file "/tmp/git-1.7.9.tar.gz" do
    source "http://git-core.googlecode.com/files/git-1.7.9.tar.gz"
  end
  execute "install_git" do
    command "cd tmp; tar -zxf git-1.7.9.tar.gz; cd git-1.7.9; ./configure; make -j3; make install"
  end
end

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key? "mirror"
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
else
  mirrors = Hash.new
end

_source_list = mirrors['maven']
if _source_list.nil?
  Chef::Log.info("maven source repository has not beed defined in cloud mirror service.. taking from default attributes #{node.build.maven_source}")
  _source_list = node.build.maven_source
else
  Chef::Log.info("maven source repository has been defined in cloud mirror service #{_source_list}")
end

# install maven3
if ::File.exists?("/opt/maven/bin/mvn") 
  Chef::Log.info("/opt/maven/bin/mvn exists.")                
else
  _target = '/usr/src/maven-3.3.9.tar'
  
  shared_download_http "#{_source_list}" do
    path _target
    action :create
  end
     
  directory "/opt" do
    recursive true
    mode 0775
    action :create
  end
  
  bash "install_maven" do
    user "root"
    cwd "/opt"
    code <<-EOH
    tar -xvf #{_target}
    ln -sf apache-maven-3.3.9 maven
    ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn
    EOH
    not_if { ::File.exists?('/usr/bin/mvn') }
  end

end

manifest = node.workorder.payLoad.RealizedAs.first['ciName']
install_dir = (node[:build].has_key?('install_dir') && !node[:build][:install_dir].empty?) ? node[:build][:install_dir] : "/opt/#{manifest}"
as_user = (node[:build].has_key?('as_user') && !node[:build][:as_user].empty?) ? node[:build][:as_user] : "root"
as_group = (node[:build].has_key?('as_group') && !node[:build][:as_group].empty?) ? node[:build][:as_group] : "root"
as_home = '/root'
if as_user != 'root'
  as_home = `cd ~#{as_user} && pwd`.chop
end

settings_xml_file = as_home + "/.m2/settings.xml"

directory "#{as_home}/.m2/" do
  action :create
  recursive true
  not_if { Chef::Config[:http_proxy].nil? }
end

template settings_xml_file do
    source "settings.xml.erb"
    owner as_user
    mode 0644
    not_if { Chef::Config[:http_proxy].nil? }
end

ci = nil
# work order
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
# action order
elsif node.workorder.has_key?("ci")
  ci = node.workorder.ci
end

_key = ci[:ciAttributes][:key]||''
_repository = ci[:ciAttributes][:repository]

# setup ssh keys if needed
unless _key.empty?

  Chef::Log.info("setup keys for user #{as_user} in home dir #{as_home}")

  if _repository =~ /(\w+)@(.+):(.+)/
    _user = $1
    _hostname = $2
    _path = $3
    # create host alias
    _repository = "#{_user}@#{manifest}:#{_path}"
  else
    _url = URI.parse(_repository)
    _user = _url.userinfo
    _hostname = _url.host
    _path = _url.path
    _repository = "#{_url.scheme}://#{_url.userinfo}@#{manifest}#{_url.path}"
  end

  directory "#{as_home}/.ssh" do
    owner as_user
    group as_group
    mode "0700"
    #not_if "test -d #{as_home}/.ssh"
  end.run_action(:create)

  file "#{as_home}/.ssh/#{manifest}_rsa" do
    owner as_user
    group as_group
    mode 0400
    content _key.gsub(/\r\n?/,"\n")
  end.run_action(:create)

  ssh_config = "#{as_home}/.ssh/config"
  stricthostkey = "StrictHostKeyChecking no"
  knownhosts = "UserKnownHostsFile /dev/null"
  hostentry = "Host #{manifest}\n\tHostName #{_hostname}\n\tUser #{_user}\n\tIdentityFile #{as_home}/.ssh/#{manifest}_rsa"
  if File.exists?(ssh_config)
    text = File.read(ssh_config)
    text.gsub!(/StrictHostKeyChecking.*/,stricthostkey) or text << stricthostkey + "\n"
    text.gsub!(/UserKnownHostsFile.*/,knownhosts) or text << knownhosts + "\n"
    text.gsub!(/Host #{manifest}.*#{manifest}_rsa/m,hostentry) or text << hostentry + "\n"
  else
    text = "#{stricthostkey}\n#{knownhosts}\n#{hostentry}\n"
  end
  File.open(ssh_config, 'w') {|f| f.write(text) }
  execute "chown #{as_user}:#{as_group} #{ssh_config}"

end  

if ci[:ciBaseAttributes] && ci[:ciBaseAttributes][:repository] && ci[:ciAttributes][:repository] != ci[:ciBaseAttributes][:repository]
  repo_dir = "#{install_dir}/shared/latest"
  Chef::Log.info("detected change in repository url - clearing out old repo dir #{repo_dir}")
  directory "#{repo_dir}" do
    recursive true
    action :delete
    only_if { File.directory?(repo_dir) }
  end
end

include_recipe "build::build_wrapper"
