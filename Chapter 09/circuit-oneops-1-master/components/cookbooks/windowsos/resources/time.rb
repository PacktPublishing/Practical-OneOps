actions :set_time_zone, :set_ntpservers

attribute :timezone_name, kind_of: String, required: false
attribute :ntpserver_names, kind_of: Array, default: 'time.windows.com'