include_recipe "golang::install_go"

include_recipe "golang::download_app_#{node.workorder.rfcCi.ciAttributes.artifact_link_type}"

include_recipe "golang::build_app"
include_recipe "golang::run_app"

