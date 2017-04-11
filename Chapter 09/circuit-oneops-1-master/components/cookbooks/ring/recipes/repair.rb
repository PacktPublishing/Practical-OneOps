nodes = node.workorder.payLoad.ManagedVia


deps = node.workorder.payLoad.DependsOn

db_type = nil
isRedis = false
deps.each do |dep|
  class_name = dep['ciClassName'].split('.').last
  db_type = dep['ciClassName'].split('.').last.downcase
  if class_name == "Redisio"
    isRedis = true
    include_recipe "ring::repair_#{db_type}"
  end
end

if !isRedis
  include_recipe "ring::add"
end
