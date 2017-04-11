actions :configure
default_action :configure

# Specifies whether dynamic compression is enabled for URLs.
attribute :static_compression, kind_of: [TrueClass, FalseClass], default: true

# Specifies whether static compression is enabled for URLs.
attribute :dynamic_compression, kind_of: [TrueClass, FalseClass], default: true

# Specifies whether the currently available response is dynamically compressed before it is put into the output cache.
attribute :dynamic_compression_before_cache, kind_of: [TrueClass, FalseClass], default: false
