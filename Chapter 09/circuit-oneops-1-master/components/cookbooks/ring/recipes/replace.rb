deps = node.workorder.payLoad.DependsOn

db_type = nil
is_redis = false
deps.each do |dep|
  db_type = dep['ciClassName'].split('.').last.downcase
  if db_type == "redisio"
    is_redis = true
    include_recipe "ring::replace_#{db_type}"
  end
end

if !is_redis
  include_recipe "ring::add"
end
