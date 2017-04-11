require File.expand_path('../base_model', __FILE__)
require File.expand_path('../label_model', __FILE__)
require 'resolv'

class LoadbalancerModel < BaseModel

  def initialize(vip_subnet_id, provider = nil, tenant_id = nil, vip_address = nil, id = nil, provisioning_status = nil, operating_status = nil)
    fail ArgumentError, 'vip_subnet_id is nil' if vip_subnet_id.nil? || vip_subnet_id.empty?

    super()
    @vip_subnet_id = vip_subnet_id
    @provider = provider
    @tenant_id = tenant_id
    @vip_address = vip_address
    @id = id
    @provisioning_status = provisioning_status
    @operating_status = operating_status
    @label = LabelModel.new
  end

  attr_reader :vip_subnet_id, :provider, :tenant_id, :vip_address, :id, :provisioning_status,
              :operating_status, :listeners

  def listeners=(listeners)
    @listeners = listeners
  end

  def serialize_optional_parameters
    options = {}
    options[:name] = @label.name
    options[:description] = @label.description
    options[:admin_state_up] = admin_state_up
    if !@provider.nil? then options[:provider] = @provider end
    if !@tenant_id.nil? then options[:tenant_id] = @tenant_id end
    if !@vip_address.nil? then options[:vip_address] = @vip_address end

    options
  end

end

