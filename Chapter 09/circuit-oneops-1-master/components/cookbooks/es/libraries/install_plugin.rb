module Extensions

  # Install an Elasticsearch plugin
  #
  # In the simplest form, just pass a plugin name in the GitHub <user>/<repo> format:
  #
  #     install_plugin 'karmi/elasticsearch-paramedic'
  #
  # You may also optionally pass a version:
  #
  #     install_plugin 'elasticsearch/elasticsearch-mapper-attachments', 'version' => '1.6.0'
  #
  # ... as well as the URL:
  #
  #     install_plugin 'hunspell', 'url' => 'https://github.com/downloads/.../elasticsearch-analysis-hunspell-1.1.1.zip'
  #
  # The "elasticsearch::plugins" recipe will install all plugins listed in
  # the role/node attributes or in the data bag (`node.elasticsearch.plugins`).
  #
  # Example:
  #
  #     { elasticsearch: {
  #         plugins: {
  #           'karmi/elasticsearch-paramedic' => {},
  #           'lukas-vlcek/bigdesk'           => { 'version' => '1.0.0' },
  #           'hunspell'                      => { 'url' => 'https://github.com/downloads/...' }
  #         }
  #       }
  #     }
  #
  # See <http://wiki.opscode.com/display/chef/Setting+Attributes+(Examples)> for more info.
  #
  def install_plugin name, params={}

    ruby_block "Install plugin: #{name}" do
      block do

        version = params['version'] ? "#{params['version']}" : nil
        url     = params['url']     ? "#{params['url']}" : nil
        
        # clean already installed kopf plugins
        clean_plugin_ver = "plugin remove #{version}"
        clean_plugin_kopf = "plugin remove kopf"
        system clean_plugin_ver
        system clean_plugin_kopf

        if url.nil?
           command = "/usr/local/bin/plugin install #{name}/#{version}"
        elsif version.start_with?("1")
          command = "/usr/local/bin/plugin --url #{url}/elasticsearch-kopf/1.1/elasticsearch-kopf-1.1.zip --install kopf"
        elsif version.start_with?("2")
          command = "/usr/local/bin/plugin install #{url}/elasticsearch-kopf/2.0.0/elasticsearch-kopf-2.0.0.zip"
        end

        Chef::Log.info("Plugin Install Command is: #{command}")

        raise "[!] Failed to install plugin" unless system command

        # Ensure proper permissions
        raise "[!] Failed to set permission" unless system "chown -R #{node.elasticsearch[:user]}:#{node.elasticsearch[:user]} #{node.elasticsearch[:dir]}/elasticsearch-#{node.elasticsearch[:version]}/plugins/"
      end

      notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]

      not_if do
        Dir.entries("#{node.elasticsearch[:dir]}/elasticsearch-#{node.elasticsearch[:version]}/plugins/").any? do |plugin|
          next if plugin =~ /^\./
          name.include? plugin
        end rescue false
      end

    end

  end

end
