
class BaseModel

  def initialize
    @admin_state_up = true
  end

  attr_reader  :admin_state_up, :label

  def admin_state_up=(admin_state_up)
    if !!admin_state_up == admin_state_up
      @admin_state_up = admin_state_up
    else
      @admin_state_up = true
    end
  end

  def label=(label)
    @label = label
  end

  def is_valid_port(protocol_port)
    port = Integer(protocol_port)
    if port >= 0 && port <= 65535
      true
    else
      fail ArgumentError, 'protocol_port is invalid'
    end
  end
  private :is_valid_port

  def validate_port(protocol_port)
    port = Integer(protocol_port)
    if port >= 0 && port <= 65535
      return port
    else
      fail ArgumentError, 'port is invalid'
    end
  end
  private :validate_port

end