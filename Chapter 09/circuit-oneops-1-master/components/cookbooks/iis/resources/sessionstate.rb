actions :configure
default_action :configure

# Name the of the web site
attribute :site_name, kind_of: String, :required => true

# Specifies how cookies are used for a Web application.
attribute :cookieless, kind_of: String, default: "UseCookies"

# Specifies the name of the cookie that stores the session identifier.
attribute :cookiename, kind_of: String, default: "ASP.NET_SessionID"

# Specifies the number of minutes a session can be idle before it is abandoned.
attribute :time_out, kind_of: Integer, default: 20, regex: /^[1-9][0-9]?$/
