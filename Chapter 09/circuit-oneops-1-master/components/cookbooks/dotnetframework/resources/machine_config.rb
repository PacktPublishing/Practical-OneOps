actions :add_or_update
default_action :add_or_update

attribute :name, kind_of: String, name_attribute: true
attribute :run_time_context, kind_of: Hash
