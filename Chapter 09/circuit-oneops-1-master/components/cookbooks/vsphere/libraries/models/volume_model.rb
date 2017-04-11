
class VolumeModel
  module Mode
    PERSISTENT = 'PERSISTENT'
    INDEPENDENT_PERSISTENT = 'INDEPENDENT_PERSISTENT'
    INDEPENDENT_NONPERSISTENT = 'INDEPENDENT_NONPERSISTENT'
  end

  def initialize(datastore, id = nil)
    fail ArgumentError, 'datastore is invalid' if datastore.nil? || datastore.empty?

    @datastore = datastore
    @id = id
    @disk_mode = 'PERSISTENT'
    @thin = true
  end

  attr_reader :datastore, :id, :name, :disk_mode, :thin_provisioned, :size_gb

  def name=(name)
    @name = name[0...80]
  end

  def disk_mode=(disk_mode)
      @disk_mode = validate_mode(disk_mode)
  end

  def thin_provisioned=(thin_provisioned)
    @thin_provisioned = validate_thin(thin_provisioned)
  end

  def size_gb=(size_gb)
    size_gb = Integer(size_gb)
    @size_gb = valid_size(size_gb)
  end

  def serialize_object
    object = {}
    object[:datastore] = @datastore
    object[:id] = @id
    object[:name] = @name
    object[:mode] = @disk_mode
    object[:thin] = @thin_provisioned
    object[:size_gb] = @size_gb

    return object
  end

  def validate_mode(mode)
    mode_upcase = mode.upcase
    if mode_upcase == Mode::PERSISTENT || mode_upcase == Mode::INDEPENDENT_PERSISTENT || mode_upcase == Mode::INDEPENDENT_NONPERSISTENT
      return mode_upcase
    else
      fail ArgumentError, 'mode is invalid'
    end
  end
  private :validate_mode

  def valid_size(size)
    if size < 2147483647 && size > -1
      return size
    else
      fail ArgumentError, 'size is invalid'
    end
  end
  private :valid_size

  def validate_thin(thin)
    return false  if thin == false  || thin =~ (/(false|f|no|n|0)$/i)
    return true
  end
end
