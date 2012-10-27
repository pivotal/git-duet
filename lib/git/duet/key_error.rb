unless defined?(KeyError)
  KeyError = Class.new(IndexError)
end
