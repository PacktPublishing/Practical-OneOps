# Create ring for nosql databases
deps = node.workorder.payLoad.DependsOn

db_type = nil
deps.each do |dep|
  
  class_name = dep['ciClassName'].split('.').last

  case class_name  
  when /Cassandra|Dse|Apache_cassandra/
    db_type = 'cassandra'
  when "Couchbase"
    db_type = class_name.downcase
  when "Hadoop"
    db_type = class_name.downcase    
  when "Mongodb"
    db_type = class_name.downcase    
  when "Rabbitmq" 
    db_type = class_name.downcase    
  when "Zookeeper" 
    db_type = class_name.downcase    
  when "Elasticsearch" 
    db_type = class_name.downcase    
  when "Redisio" 
    db_type = class_name.downcase    
  when "Kafka" 
    db_type = class_name.downcase    
  when "Graphite" 
    db_type = class_name.downcase    
  when "Mirrormaker" 
    db_type = class_name.downcase
  when "Storm"
    db_type = class_name.downcase    
  when "Stream-splitter" 
    db_type = class_name.downcase    
  else
    puts "ERROR: Did not find database or messaging system type for #{class_name}..."    
  end
  break unless db_type.nil?

end

include_recipe "ring::#{db_type}"
