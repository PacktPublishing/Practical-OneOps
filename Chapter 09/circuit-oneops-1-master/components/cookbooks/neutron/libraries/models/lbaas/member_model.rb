require File.expand_path('../base_model', __FILE__)
require File.expand_path('../label_model', __FILE__)
require 'resolv'

class MemberModel < BaseModel

  def initialize(ip_address, protocol_port, subnet_id, tenant_id = nil, id = nil, operating_status = nil)
    fail ArgumentError, 'ip_address is invalid' if ip_address.nil? || ip_address.empty? || !((ip_address =~ Resolv::IPv4::Regex) || (ip_address =~ Resolv::IPv6::Regex))
    fail ArgumentError, 'protocol_port is invalid' if protocol_port.nil? || !is_valid_port(protocol_port)
    fail ArgumentError, 'subnet_id is invalid' if subnet_id.nil? || subnet_id.empty?

    super()
    @ip_address = ip_address
    @protocol_port = protocol_port
    @subnet_id = subnet_id
    @tenant_id = tenant_id
    @id = id
    @operating_status = operating_status
    @weight = 1
    @label = LabelModel.new
  end

  attr_reader :ip_address, :subnet_id, :tenant_id, :id, :operating_status, :protocol_port, :weight

  def protocol_port=(protocol_port)
    if is_valid_port(protocol_port)
      @protocol_port = protocol_port
    end
  end

  def weight=(weight)
    if weight.is_a?(Integer)
      @weight = validate_weight(weight)
    else
      @weight = 1
    end
  end

  def serialize_optional_parameters
    options = {}
    options[:name] = @label.name
    options[:admin_state_up] = admin_state_up
    options[:weight] = @weight
    if !@tenant_id.nil? then options[:tenant_id] = @tenant_id end

    options
  end

  def validate_weight(weight)
    if weight < 0 || weight > 256
      weight = 1
    end
    return weight
  end
  private :validate_weight

end

