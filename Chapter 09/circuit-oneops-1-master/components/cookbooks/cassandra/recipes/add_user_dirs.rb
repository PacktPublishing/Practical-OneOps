user "cassandra" do
  gid "nobody"
  shell "/bin/false"
end

directory "/opt/cassandra/lib.so" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/lib/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/run/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/log/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory_options = [
  "data_file_directories",
  "saved_caches_directory",
  "commitlog_directory"
]

if node.workorder.rfcCi.ciAttributes.has_key?("config_directives")
  
  options = JSON.parse(node.workorder.rfcCi.ciAttributes.config_directives)
  directory_options.each do |dir|    
    next if !options.has_key?(dir)
    
    dirs = []
    begin
      dir_value = JSON.parse(options[dir])
    rescue Exception => e
      # assume string
      dir_value = options[dir]
    end
    if dir_value.class == Array
      dirs += dir_value
    else
      dirs.push(dir_value)
    end
    
    dirs.each do |d|
      directory d do
        owner "cassandra"
        group "root"
        mode "0755"
        recursive true
        action :create
      end
    end

  end   
end