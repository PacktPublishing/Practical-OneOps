require File.expand_path('../base_model', __FILE__)

class LabelModel

  def initialize
    @name = ''
    @description = ''
  end

  attr_reader  :name, :description

  def name=(name)
    @name = truncate_to_max_length(name)
  end

  def description=(description)
    @description = truncate_to_max_length(description)
  end

  def truncate_to_max_length(value)
    return value[0..254]
  end
  private :truncate_to_max_length
end