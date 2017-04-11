actions :create, :update, :recycle
default_action :create

# These attributes are defined in http://msdn.microsoft.com/en-us/library/ms690608(v=vs.90).aspx

# Allowed time intervals are of form [-][d.]hh:mm:ss[.ff]

attribute :name, kind_of: String, name_attribute: true

attribute :managed_runtime_version, kind_of: String, default: "v4.0", equal_to: ["v2.0", "v4.0"]
attribute :managed_pipeline_mode, kind_of: Symbol, default: :integrated, equal_to: [:classic, :integrated]
attribute :enable32_bit_app_on_win64, kind_of: [TrueClass, FalseClass], default: false

attribute :cpu_action, kind_of: String, default: "NoAction", equal_to: ["NoAction", "KillW3wp"]
attribute :cpu_limit, kind_of: Integer, default: 0
attribute :cpu_reset_interval, kind_of: String, default: "00:05:00"

attribute :process_model_idle_timeout, kind_of: String, default: "00:20:00"
attribute :process_model_max_processes, kind_of: Integer, default: 1
attribute :process_model_pinging_enabled, kind_of: [TrueClass, FalseClass], default: true
attribute :process_model_ping_interval, kind_of: String, default: "00:00:30"
attribute :process_model_ping_response_time, kind_of: String, default: "00:01:30"
attribute :process_model_shutdown_time_limit, kind_of: String, default: "00:01:30"
attribute :process_model_startup_time_limit, kind_of: String, default: "00:01:30"
attribute :process_model_identity_type, kind_of: String, default: "ApplicationPoolIdentity", equal_to: ["LocalSystem", "LocalService", "NetworkService", "SpecificUser", "ApplicationPoolIdentity"]
attribute :process_model_user_name, kind_of: String, default: ""
attribute :process_model_password, kind_of: String, default: ""

attribute :recycling_disallow_overlapping_rotation, kind_of: [TrueClass, FalseClass], default: false
attribute :recycling_disallow_rotation_on_config_change, kind_of: [TrueClass, FalseClass], default: false
attribute :recycling_log_event_on_recycle, kind_of: Array, default: ["Time", "Memory", "PrivateMemory"]

attribute :recycling_periodic_restart_memory, kind_of: Integer, default: 0
attribute :recycling_periodic_restart_private_memory, kind_of: Integer, default: 0
attribute :recycling_periodic_restart_requests, kind_of: Integer, default: 0
attribute :recycling_periodic_restart_schedule, kind_of: Array, default: []
attribute :recycling_periodic_restart_time, kind_of: String, default: "00:00:00"

attribute :failure_rapid_fail_protection, kind_of: [TrueClass, FalseClass], default: true
attribute :failure_rapid_fail_protection_interval, kind_of: String, default: "00:05:00"
attribute :failure_rapid_fail_protection_max_crashes, kind_of: Integer, default: 5
