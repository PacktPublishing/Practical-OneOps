#Cache log Defaults
default["diagnostic-cache"]["user"] = "app"
default["diagnostic-cache"]["group"] = "app"
default["diagnostic-cache"]["log_dir"] = "/opt/diagnostic-cache/log"
default["diagnostic-cache"]["install_root_dir"] = "/opt"
default["diagnostic-cache"]["install_app_dir"] = "/diagnostic-cache"

include_attribute "couchbase"
