
class NicModel
  def initialize(network, name)
    fail ArgumentError, 'network is invalid' if network.nil? || network.empty?
    fail ArgumentError, 'name is invalid' if name.nil?  || name.empty?

    @network = network
    @name = name
    @summary = ''
  end

  attr_reader :network, :name, :status, :summary

  def status=(status)
    @status = status
  end

  def summary=(summary)
    @summary = summary
  end

  def serialize_object
    options = {}
    options[:network] = @network
    options[:name] = @name
    options[:status] = @status
    options[:summary] = @summary

    return options
  end
end
