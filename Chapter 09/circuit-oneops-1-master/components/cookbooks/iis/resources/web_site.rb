actions :create, :update, :delete
default_action :create


attribute :name, kind_of: String, name_attribute: true

attribute :id, kind_of: Integer, default: 999
attribute :server_auto_start, kind_of: [TrueClass, FalseClass], default: true
attribute :virtual_directory_path, kind_of: String, default: '/'
attribute :virtual_directory_physical_path, kind_of: String, default: 'c:/apps'
attribute :bindings, kind_of: Array
attribute :application_path, kind_of: String, default: '/'
attribute :application_pool, kind_of: String, default: 'defaultapppool'
attribute :certificate_hash, kind_of: String, default: ''
attribute :certificate_store_name, kind_of: String, default: 'MY'
