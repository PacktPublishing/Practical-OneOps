actions :add
default_action :add

# Name the of the web site
attribute :site_name, kind_of: String, required: true

# Specifies a unique file name extension for a MIME type.
attribute :file_extension, kind_of: String, required: true

# Specifies the type of file and the application that uses this kind of file name extension.
attribute :mime_type, kind_of: String, required: true
