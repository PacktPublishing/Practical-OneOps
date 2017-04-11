require 'hyperkit'

rfcCi = node[:workorder][:rfcCi]

cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

client_cert = "#{Chef::Config[:file_cache_path]}/client_#{rfcCi[:ciId]}.crt"
client_key = "#{Chef::Config[:file_cache_path]}/client_#{rfcCi[:ciId]}.key"

file client_cert do
  mode 0644
  content cloud[:client_cert]
end

file client_key do
  mode 0644
  content cloud[:client_key]
end

lxd = Hyperkit::Client.new(
            api_endpoint: "https://designare.home:1443",
            client_cert: client_cert,
            client_key: client_key,
            verify_ssl: false,
            auto_sync: false
          )

ruby_block "delete #{node[:server_name]}" do
  block do
    begin
      server = lxd.container(node[:server_name])
      Chef::Log.info("delete server")
      lxd.stop_container(node[:server_name])
      sleep 5
      delete = lxd.delete_container(node[:server_name])
      Chef::Log.debug(delete.inspect)
    rescue Exception => e
      if e.class.name == 'Hyperkit::NotFound'
        Chef::Log.info("server not found, assuming already deleted")
      else
        raise e.inspect
      end
    end
  end
end
