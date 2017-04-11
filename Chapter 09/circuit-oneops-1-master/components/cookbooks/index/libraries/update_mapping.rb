module IndexHelper
  
require 'net/http'
 
  def update_mapping host, path, payload
    req = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})
    req.body = payload
    response = Net::HTTP.new(host, 9200).start {|http| http.request(req) }
    puts "Response #{response.code} #{response.message}:
    #{response.body}"
  end

end