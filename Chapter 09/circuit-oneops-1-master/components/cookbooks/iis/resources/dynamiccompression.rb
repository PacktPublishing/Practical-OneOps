actions :configure
default_action :configure

# Compression level - from 0 (none) to 10 (maximum)
attribute :level, kind_of: Integer, default: 0

# Which mime-types will be / will not be compressed
attribute :mime_types, kind_of: Hash, default: {
  "text/*" => true,
  "message/*" => true,
  "application/x-javascript" => true,
  "*/*" => false
}

# The percentage of CPU utilization (0-100) above which compression is disabled
attribute :cpu_usage_to_disable, kind_of: Integer, default: 90

# The percentage of CPU utilization (0-100) below which compression is re-enabled after disable due to excess usage
attribute :cpu_usage_to_reenable, kind_of: Integer, default: 50

#The directory where compressed versions of static files are temporarily stored and cached.
attribute :directory, kind_of: String, default: '%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files'
