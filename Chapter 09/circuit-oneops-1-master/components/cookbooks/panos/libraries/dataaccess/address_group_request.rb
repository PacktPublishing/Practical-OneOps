

class AddressGroupRequest

  # initialize the class making sure we have a URL endpoint and a KEY to use when communicating
  # to the firewall device
  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' unless key.is_a? Key

    @baseurl = url
    @key = key
  end

  def create(address_group, address = nil)
		fail ArgumentError, 'address_group must be of type AddressGroup' unless address_group.is_a? AddressGroup

		if address_group.type =~ /Dynamic/
			element = "<entry name='#{address_group.name}'><dynamic><filter>'#{address_group.criteria}'</filter></dynamic></entry>"
		else
			# this is a static type address group, it requires an address to add to the group
			raise Exception.new('Address is required to configure a STATIC type address group') if address.nil?
			raise Exception.new('Address must be of type Address') unless address.is_a? Address
			element = "<entry name='#{address_group.name}'<static><member>#{address.name}</member></static>"
		end

		begin
    	set_ag_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'config',
    				:action => 'set',
    				:xpath => "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='#{address_group.device_group}']/address-group",
    				:element => element
    			}
    		}
    	)
      dag_hash = Crack::XML.parse(set_ag_response)
      Chef::Log.info("dag_hash is: #{dag_hash}")
      raise Exception.new("PANOS Error creating a DAG: #{dag_hash['response']['msg']}") if dag_hash['response']['status'] == 'error'
    rescue => e
      raise Exception.new("Exception creating DAG: #{e} ")
    end
  end

  def delete(name, device_group)
    begin
    	delete_ag_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'config',
    				:action => 'delete',
            :xpath => "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='#{device_group}']/address-group/entry[@name='#{name}']"
    			}
    		}
    	)
      dag_hash = Crack::XML.parse(delete_ag_response)
      Chef::Log.info("delete_dag_hash is: #{dag_hash}")
      raise Exception.new("PANOS Error deleting a DAG: #{dag_hash['response']['msg']}") if dag_hash['response']['status'] == 'error'
    rescue => e
      raise Exception.new("Exception deleting DAG: #{e} ")
    end
  end

end
