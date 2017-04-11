include_recipe "golang::go_run_#{node.workorder.rfcCi.ciAttributes.artifact_type}"
#include_recipe "golang::go_run_#{node[:golang][:artifact_type]}"