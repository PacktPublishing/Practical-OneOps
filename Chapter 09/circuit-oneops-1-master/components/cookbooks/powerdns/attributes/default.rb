
# powerdns Mash.new unless attribute?("powerdns")
# powerdns[:server] = Mash.new unless powerdns.has_key?(:server)
# powerdns[:server][:ns1] = "ns1." + fqdn unless powerdns[:server].has_key?(:ns1)
# powerdns[:server][:ns2] = "ns2." + fqdn unless powerdns[:server].has_key?(:ns2)
# powerdns[:server][:hostmaster] = "hostmaster." + fqdn unless powerdns[:server].has_key?(:hostmaster)