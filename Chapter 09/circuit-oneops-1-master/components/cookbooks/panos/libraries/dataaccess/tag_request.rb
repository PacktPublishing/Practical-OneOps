class TagRequest

  # initialize the class making sure we have a URL endpoint and a KEY to use when communicating
  # to the firewall device
  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' unless key.is_a? Key

    @baseurl = url
    @key = key
  end

  def create(tag_name, device_group)
    begin
    	tag_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'config',
    				:action => 'set',
    				:xpath => "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='#{device_group}']/tag",
    				:element => "<entry name='#{tag_name}'/>"
    			}
    		}
    	)
      create_hash = Crack::XML.parse(tag_response)
      Chef::Log.info("create_tag_hash is: #{create_hash}")
      raise Exception.new("PANOS Error creating address: #{create_hash['response']['msg']}") if create_hash['response']['status'] == 'error'
    rescue => e
      raise Exception.new("Exception creating the tag: #{e} ")
    end
  end

end
