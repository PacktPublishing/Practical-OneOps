actions :configure
default_action :configure

# Specifies the directory where central w3C log entries are written.
attribute :central_w3c_log_file_directory, kind_of: String, default: '%SystemDrive%\inetpub\logs\LogFiles'

# Specifies the directory where binary log entries are written.
attribute :central_binary_log_file_directory, kind_of: String, default: '%SystemDrive%\inetpub\logs\LogFiles'
