class PanosJob

  attr_reader :id

  def initialize(id)
    fail ArgumentError, 'id cannot be nil' if id.nil?
    fail ArgumentError, 'id must be an Integer' unless id.is_a?(Integer)

    super()
    @id = id
  end

end
