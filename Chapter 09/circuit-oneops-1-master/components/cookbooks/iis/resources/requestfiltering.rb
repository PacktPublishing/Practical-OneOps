actions :configure
default_action :configure

# If set to true, request filtering will allow URLs with doubly-escaped characters.
# If set to false, request filtering will deny the request if characters that have been escaped twice are present in URLs.
attribute :allow_double_escaping, kind_of: [TrueClass, FalseClass], default: false

# If set to true, request filtering will allow non-ASCII characters in URLs.
# If set to false, request filtering will deny the request if high-bit characters are present in URLs.
attribute :allow_high_bit_characters, kind_of: [TrueClass, FalseClass], default: true

# Specifies which HTTP verbs are allowed or denied to limit types of requests sent to the Web server.
attribute :verbs, kind_of: Hash, default: {}

# Specifies the maximum length of content in a request, in bytes.
attribute :max_allowed_content_length, kind_of: Integer, default: 30000000

# Specifies the maximum length of the query string, in bytes.
attribute :max_url, kind_of: Integer, default: 4096

# Specifies the maximum length of the URL, in bytes.
attribute :max_query_string, kind_of: Integer, default: 2048

# Specifies whether the Web server should process files that have unlisted file name extensions.
attribute :file_extension_allow_unlisted, kind_of: [TrueClass, FalseClass], default: true
