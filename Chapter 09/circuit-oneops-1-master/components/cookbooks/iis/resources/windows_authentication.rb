actions :configure
default_action :configure

# Name the of the web site
attribute :site_name, kind_of: String, required: true

# Setting this flag to true specifies that authentication persists only for a single request on a connection.
attribute :auth_persist_single_request, kind_of: [TrueClass, FalseClass], default: false

# Specifies whether Windows authentication is enabled.
attribute :enabled, kind_of: [TrueClass, FalseClass], default: false

# Specifies whether Windows authentication is done in kernel mode. True specifies that Windows authentication uses kernel mode.
attribute :use_kernel_mode, kind_of: [TrueClass, FalseClass], default: true
