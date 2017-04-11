
class CdromModel
  def initialize(datastore, iso, instance_uuid = nil)
    fail ArgumentError, 'datastore is invalid' if datastore.nil? || datastore.empty?
    fail ArgumentError, 'iso is invalid' if iso.nil?  || iso.empty?

    @datastore = datastore
    @iso = iso
    @instance_uuid = instance_uuid
    @start_connected = true
    @allow_guest_control = true
    @connected = true
  end

  attr_reader :datastore, :iso, :instance_uuid, :start_connected, :allow_guest_control, :connected

  def start_connected=(start_connected)
    if !!start_connected == start_connected
      @start_connected = start_connected
    else
      @start_connected = true
    end
  end

  def allow_guest_control=(allow_guest_control)
    if !!allow_guest_control == allow_guest_control
      @allow_guest_control = allow_guest_control
    else
      @allow_guest_control = true
    end
  end

  def connected=(connected)
    if !!connected == connected
      @connected = connected
    else
      @connected = true
    end
  end

  def serialize_object
    options = {}
    options['instance_uuid'] = @instance_uuid
    options['datastore'] = @datastore
    options['iso'] = @iso
    options['start_connected'] = @start_connected
    options['allow_guest_control'] = @allow_guest_control
    options['connected'] = @connected

    return options
  end
end
