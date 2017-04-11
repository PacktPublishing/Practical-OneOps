#
# Cookbook Name:: f5-bigip
# Library:: matchers
#

if defined?(ChefSpec)
  ChefSpec.define_matcher :f5_ltm_monitor
  ChefSpec.define_matcher :f5_ltm_node
  ChefSpec.define_matcher :f5_ltm_pool
  ChefSpec.define_matcher :f5_ltm_virtual_server
  ChefSpec.define_matcher :f5_config_sync

  def create_f5_ltm_monitor(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_monitor, :create, resource_name)
  end

  def delete_f5_ltm_monitor(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_monitor, :delete, resource_name)
  end

  def create_f5_ltm_node(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_node, :create, resource_name)
  end

  def delete_f5_ltm_node(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_node, :delete, resource_name)
  end

  def create_f5_ltm_pool(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_pool, :create, resource_name)
  end

  def delete_f5_ltm_pool(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_pool, :delete, resource_name)
  end

  def create_f5_ltm_virtual_server(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_virtual_server, :create, resource_name)
  end

  def delete_f5_ltm_virtual_server(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_ltm_virtual_server, :delete, resource_name)
  end

  def run_f5_config_sync(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:f5_config_sync, :run, resource_name)
  end
end
