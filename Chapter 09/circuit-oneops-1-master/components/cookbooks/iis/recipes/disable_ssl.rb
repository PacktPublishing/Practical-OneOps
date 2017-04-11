ssl_keys = [ccs: "current_control_set".camelize, control: "control".camelize, \
   sp: "security_providers".camelize, protocols: "protocols".camelize, \
   server: "server".camelize, sl: "schannel".upcase, ssl3: "ssl 3.0".upcase, \
   client: "client".camelize, ssl2: "ssl 2.0".upcase, \
   reg_prefix: "HKEY_LOCAL_MACHINE\\SYSTEM" \
  ]

hklm_ssl_key = [
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ssl2>s\\%<client>s" % ssl_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ssl2>s\\%<server>s" % ssl_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ssl3>s\\%<client>s" % ssl_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ssl3>s\\%<server>s" % ssl_keys,
]

hklm_ssl_key.each do | ssl_registry_key |
  registry_key ssl_registry_key do
    values [{name: "DisabledByDefault", :type => :dword, :data => '1'},
            {name: "Enabled" % ssl_keys, :type => :dword, :data => '0'}]
    recursive true
    action :create_if_missing
  end
end
