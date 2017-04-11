class Key

  attr_reader :value

  def initialize(value)
    fail ArgumentError, 'value cannot be nil' if value.nil?

    super()
    @value = value
  end

end
