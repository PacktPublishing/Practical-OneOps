tls_keys = [ccs: "current_control_set".camelize, control: "control".camelize, \
   sp: "security_providers".camelize, protocols: "protocols".camelize, \
   server: "server".camelize, sl: "schannel".upcase, tls1: "tls 1.0".upcase, \
   client: "client".camelize, tls2: "tls 2.0".upcase, tls3: "tls 3.0".upcase, \
   reg_prefix: "HKEY_LOCAL_MACHINE\\SYSTEM" \
  ]

hklm_tls_key = [
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls1>s\\%<client>s" % tls_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls1>s\\%<server>s" % tls_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls2>s\\%<client>s" % tls_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls2>s\\%<server>s" % tls_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls3>s\\%<client>s" % tls_keys,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<tls3>s\\%<server>s" % tls_keys,
]

hklm_tls_key.each do | tls_registry_key |
  registry_key tls_registry_key do
    values [{name: "DisabledByDefault", :type => :dword, :data => '0'},
            {name: "Enabled", :type => :dword, :data => '1'}]
    recursive true
    action :create_if_missing
  end
end
