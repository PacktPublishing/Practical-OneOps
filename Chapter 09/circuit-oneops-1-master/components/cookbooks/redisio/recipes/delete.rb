include_recipe "redisio::disable"
# The uninstall recipe, and LWRP are used to remove the configuration files and redis binaries. This is not commonly used and may be removed in future releases... so, commented here  include_recipe "redisio::uninstall"
