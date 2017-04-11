actions :import
default_action :import

#friendly name of the certificate
attribute :name, kind_of: String, name_attribute: true
#base64 encoding format
attribute :raw_data, kind_of: String, required: true
attribute :password, kind_of: String, required: true
