

ruby_block "create namespace #{node[:realm]}" do
  block do
    Chef::Log.info("kubectl create namespace #{node[:realm]} -o json 2>&1`")
    result = `kubectl create namespace #{node[:realm]} -o json 2>&1`
    if $?.success?
      Chef::Log.info(JSON.parse(result))
    else
      if result.match("already exists")
        Chef::Log.info(result)
      else
        raise result
      end
    end
  end
end
