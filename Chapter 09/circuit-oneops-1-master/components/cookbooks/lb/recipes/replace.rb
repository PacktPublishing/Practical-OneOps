# set rfcAction so connection doesn't generate off manifest id
node.set["rfcAction"] = "delete"
include_recipe "lb::delete"
node.set["rfcAction"] = "replace"
include_recipe "lb::add"
