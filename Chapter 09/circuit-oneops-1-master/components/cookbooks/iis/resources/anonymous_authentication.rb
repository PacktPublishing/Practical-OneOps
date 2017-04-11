actions :configure
default_action :configure

# Name the of the web site
attribute :site_name, kind_of: String, :required => true

# Specifies whether Anonymous authentication is enabled.
attribute :enabled, kind_of: [TrueClass, FalseClass], default: true

# The logonMethod attribute can be one of the following possible values. The default is ClearText.
attribute :logon_method, kind_of: String, default: 'ClearText', equal_to: ['Batch', 'ClearText', 'Interactive', 'Network']

# Specifies the username for Anonymous authentication
attribute :username, kind_of: String, default: 'IUSR'

# Specifies the password for Anonymous authentication.
attribute :password, kind_of: String
