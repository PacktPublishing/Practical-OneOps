module IndexHelper
  
require "json"
 
  def is_valid_json json
    begin
      JSON.parse(json)
      return true
    rescue Exception => e
      Chef::Log.error(e)
      return false
    end
  end
  
end