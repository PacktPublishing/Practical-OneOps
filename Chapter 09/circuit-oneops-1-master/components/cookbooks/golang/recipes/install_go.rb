node.set['golang']['platform'] = node['kernel']['machine'] =~ /i.86/ ? '386' : 'amd64'

node.set['golang']['go_from_source'] = "#{node.workorder.rfcCi.ciAttributes.go_from_source}"
node.set['golang']['go_version'] = "#{node.workorder.rfcCi.ciAttributes.go_version}"
node.set['golang']['go_install_dir'] = "#{node.workorder.rfcCi.ciAttributes.go_install_dir}"
node.set['golang']['gopath'] = "#{node.workorder.rfcCi.ciAttributes.gopath}"
node.set['golang']['gobin'] = "#{node.workorder.rfcCi.ciAttributes.gobin}"
node.set['golang']['go_scm'] = "#{node.workorder.rfcCi.ciAttributes.go_scm}"
node.set['golang']['go_owner'] = "#{node.workorder.rfcCi.ciAttributes.go_owner}"
node.set['golang']['go_group'] = "#{node.workorder.rfcCi.ciAttributes.go_group}"
node.set['golang']['go_download_url'] = "#{node.workorder.rfcCi.ciAttributes.go_download_url}"
node.set['golang']['go_source_method'] = "#{node.workorder.rfcCi.ciAttributes.go_source_method}"
node.set['golang']['go_mode'] = "#{node.workorder.rfcCi.ciAttributes.go_mode}"

golang_filename = "go#{node.workorder.rfcCi.ciAttributes.go_version}.#{node['os']}-#{node['golang']['platform']}.tar.gz"
if node.workorder.rfcCi.ciAttributes.go_from_source == true
  golang_filename  = "go#{node.workorder.rfcCi.ciAttributes.go_version}.src.tar.gz"
end
node.set['golang']['filename'] = golang_filename

node.default['golang']['url'] = "#{node['golang']['go_download_url']}#{node['golang']['filename']}"

bash "install-golang" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    rm -rf go
    rm -rf #{node['golang']['go_install_dir']}/go
    tar -C #{node['golang']['go_install_dir']} -xzf #{node['golang']['filename']}
  EOH
  not_if { node['golang']['go_from_source'] }
  action :nothing
end

bash "build-golang" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    rm -rf go
    rm -rf #{node['golang']['go_install_dir']}/go
    tar -C #{node['golang']['go_install_dir']} -xzf #{node['golang']['filename']}
    cd #{node['golang']['go_install_dir']}/go/src
    mkdir -p $GOBIN
    ./#{node['golang']['go_source_method']}
  EOH
  environment ({
    'GOROOT' => "#{node['golang']['go_install_dir']}/go",
    'GOBIN'  => '$GOROOT/bin',
    'GOOS'   => node['golang']['os'],
    'GOARCH' => node['golang']['arch'],
    'GOARM'  => node['golang']['arm']
  })
  only_if { node['golang']['go_from_source'] }
  action :nothing
end

if node['golang']['go_from_source']
  case node["platform"]
  when 'debian', 'ubuntu'
    packages = %w(build-essential)
  when 'redhat', 'centos', 'fedora'
    packages = %w(gcc glibc-devel)
  end
  packages.each do |dev_package|
    package dev_package do
      action :install
    end
  end
end

remote_file File.join(Chef::Config[:file_cache_path], node['golang']['filename']) do
  source node['golang']['url']
  owner 'root'
  mode 0644
  notifies :run, 'bash[install-golang]', :immediately
  notifies :run, 'bash[build-golang]', :immediately
  not_if "#{node['golang']['go_install_dir']}/go/bin/go version | grep \"go#{node['golang']['go_version']} \""
end


directory node['golang']['gopath'] do
  action :create
  recursive true
  mode 0777
  owner node['golang']['go_owner']
  group node['golang']['go_group']
  mode node['golang']['go_mode']
end

directory node['golang']['gobin'] do
  action :create
  recursive true
  mode 0777
  owner node['golang']['go_owner']
  group node['golang']['go_group']
  mode node['golang']['go_mode']
end

template "/etc/profile.d/golang.sh" do
  source "golang.sh.erb"
  owner 'root'
  group 'root'
  mode 0755
end

if node['golang']['go_scm']
  %w(git mercurial bzr).each do |scm|
    package scm
  end
end
