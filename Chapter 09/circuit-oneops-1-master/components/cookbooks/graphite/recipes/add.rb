# graphite setup
include_recipe "graphite::base_install"

# nginx and uwsgi config
include_recipe "graphite::base_install_graphite_web"

include_recipe "graphite::restart"