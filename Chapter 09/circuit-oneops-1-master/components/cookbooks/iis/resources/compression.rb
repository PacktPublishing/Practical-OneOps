actions :configure
default_action :configure

# Does a limit exist for the amount of disk space that compressed files can occupy?
attribute :disk_space_limited, kind_of: [TrueClass, FalseClass], default: true

# Disk space limit (in megabytes), that compressed files can occupy
attribute :max_disk_usage, kind_of: Integer, default: 100

# The minimum file size (in bytes) for a file to be compressed
attribute :min_file_size_to_compress, kind_of: Integer, default: 2400

#
attribute :directory, kind_of: String, default: '%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files'
