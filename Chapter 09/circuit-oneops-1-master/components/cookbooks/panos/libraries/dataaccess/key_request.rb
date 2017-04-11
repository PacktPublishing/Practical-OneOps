require File.expand_path('../../models/key.rb', __FILE__)

class KeyRequest

  def initialize(url, userid, password)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'userid cannot be nil' if userid.nil?
    fail ArgumentError, 'password cannot be nil' if password.nil?

    @url = url
    @userid = userid
    @password = password
  end

  def getkey
    begin
      key_response = RestClient::Request.execute(
        :method => :get,
        :verify_ssl => false,
        :url => @url,
        :headers => {
          :params => {
            :type => 'keygen',
            :user => @userid,
            :password => @password
          }
        }
      )
      # parse the xml to get the key
      key_hash = Crack::XML.parse(key_response)
      Chef::Log.info("key_hash is: #{key_hash}")
      raise Exception.new("PANOS Error getting key: #{key_hash['response']['msg']}") if key_hash['response']['status'] == 'error'

      key = Key.new(key_hash['response']['result']['key'])
      return key
    rescue => e
      raise Exception.new("Excpetion getting key: #{e}")
    end
  end

end
