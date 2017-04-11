# setup proxy
_proxy_map = {}
if node.workorder.rfcCi.ciAttributes.has_key?("proxy_map") &&
   !node.workorder.rfcCi.ciAttributes.proxy_map.empty?

  _proxy_map = JSON.parse(node.workorder.rfcCi.ciAttributes.proxy_map)
end
_proxy_map.each_key do |key|
  Chef::Log.info("using #{key}_proxy: #{_proxy_map[key]}")

  # needs the symbol not a string
  case key
  when "http"
    Chef::Config[:http_proxy] = _proxy_map[key]
  when "no"
    Chef::Config[:no_proxy] = _proxy_map[key]
  when "https"
    Chef::Config[:https_proxy] = _proxy_map[key]
  end
  chef_config_file = "/home/oneops/components/cookbooks/chef.rb"

  grep = "/bin/grep"
  if !::File.exist?(grep)
    grep = "/usr/bin/grep"
  end

  proxy_config_line = key+"_proxy \"#{_proxy_map[key]}\""
  execute "echo '#{proxy_config_line}' >> #{chef_config_file}" do
    not_if "#{grep} #{key}_proxy #{chef_config_file}"
  end

  # handle updates
  execute "sed -i 's@#{key}_proxy.*$@#{proxy_config_line}@' #{chef_config_file}"
end
