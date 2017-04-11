class String
  def camelize
    self.gsub(/(?<=_|^)(\w)/){$1.upcase}.gsub(/(?:_)(\w)/,'\1')
  end

  def to_bool
    return true if self =~ (/^(true|t|yes|y|1)$/i)
    return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)

    raise ArgumentError.new "invalid value: #{self}"
  end

  def to_h
    hash_object = JSON.parse(self)
    hash_object.each do | key, value |
      hash_object[key] = false if value.downcase == "false"
      hash_object[key] = true if value.downcase == "true"
    end
    hash_object
  end

end
