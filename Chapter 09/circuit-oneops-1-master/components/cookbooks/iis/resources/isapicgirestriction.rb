actions :configure
default_action :configure

# Specifies whether unlisted ISAPI modules are allowed to run on this server.
attribute :not_listed_isapis_allowed, kind_of: [TrueClass, FalseClass], default: false

# Specifies whether unlisted ISAPI modules are allowed to run on this server.
attribute :not_listed_cgis_allowed, kind_of: [TrueClass, FalseClass], default: false
