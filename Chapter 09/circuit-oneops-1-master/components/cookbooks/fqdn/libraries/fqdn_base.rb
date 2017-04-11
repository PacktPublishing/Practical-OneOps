# A base/util module for fqdn.
#
# Cookbook Name:: fqdn
# Library:: fqdn_base
#
# Author : OneOps
# Apache License, Version 2.0
require 'resolv'
require 'ipaddr'


module Fqdn

  module Base

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut
    
    
    def is_hijackable (dns_name,ns)
      is_hijackable = false
      cmd = "dig +short TXT txt-#{dns_name} @#{ns}"  
      Chef::Log.info(cmd)
      vals = `#{cmd}`.split("\n")
      vals.each do |val|
        # check that hijack is set from a different domain
        is_hijackable = true if val.include?("hijackable") && !val.include?(node.customer_domain)
      end

      Chef::Log.info("is_hijackable: #{is_hijackable}")
      return is_hijackable
    end
    
    
    def get_existing_dns (dns_name,ns)
      existing_dns = Array.new
      if dns_name =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
        ptr_name = $4 +'.' + $3 + '.' + $2 + '.' + $1 + '.in-addr.arpa'
        cmd = "dig +short PTR #{ptr_name} @#{ns}"
        Chef::Log.info(cmd)
        existing_dns += `#{cmd}`.split("\n").map! { |v| v.gsub(/\.$/,"") }
      elsif dns_name =~ Resolv::IPv6::Regex ###check this !!
        ptr_name= IPAddr.new(dns_name).reverse
        cmd = "dig +short PTR #{ptr_name} @#{ns}"
        Chef::Log.info(cmd)
        existing_dns += `#{cmd}`.split("\n").map! { |v| v.gsub(/\.$/,"") }
      else
        ["A", "AAAA", "CNAME"].each do |record_type|
          Chef::Log.info("dig +short #{record_type} #{dns_name} @#{ns}")
          vals = `dig +short #{record_type} #{dns_name} @#{ns}`.split("\n").map! { |v| v.gsub(/\.$/,"") }
          # skip dig's lenient A record lookup thru CNAME
          next if (record_type == "A" && vals.size > 1 && vals[0] !~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) || (record_type == "AAAA" && vals.size > 1 && vals[0] !~ Resolv::IPv6::Regex
          )
          existing_dns += vals

        end
      end
      Chef::Log.info("existing: "+existing_dns.sort.inspect)
      return existing_dns
    end    

    
    # get dns record type - check for ip addresses
    def get_record_type (dns_name, dns_values)
      record_type = "cname"
      ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
      dns_values.each do |dns_value|
        if dns_value =~ Resolv::IPv6::Regex
          record_type = "aaaa"
        end
      end


      if ips.size > 0
        record_type = "a"
      end
      if dns_name =~ /^\d+\.\d+\.\d+\.\d+$/ || dns_name =~ Resolv::IPv6::Regex
        record_type = "ptr"
      end
      if dns_name =~ /^txt-/
        record_type = "txt"
      end
      return record_type
    end
    
    
    def get_provider
      cloud_name = node[:workorder][:cloud][:ciName]
      provider_service = node[:workorder][:services][:dns][cloud_name][:ciClassName].split(".").last.downcase
      provider = "fog"
      if provider_service =~ /infoblox|azuredns|designate|ddns/
        provider = provider_service
      end
      Chef::Log.debug("Provider is: #{provider}")  
      return provider
    end

    def fail_with_fault(msg)
      puts "***FAULT:FATAL=#{msg}"
      Chef::Application.fatal!(msg)
    end

    # get dns value using dns_record attr or if empty resort to case stmt based on component class
    def get_dns_values (components)
      values = Array.new
      components.each do |component|
    
        attrs = component[:ciAttributes]
    
        dns_record = attrs[:dns_record] || ''
    
        # backwards compliance: until all computes,lbs,clusters have dns_record populated need to get via case stmt
        if dns_record.empty?
          case component[:ciClassName]
          when /Compute/
            if attrs.has_key?("public_dns") && !attrs[:public_dns].empty?
             dns_record = attrs[:public_dns]+'.'
            else
             dns_record = attrs[:public_ip]
            end
    
            if location == ".int" || dns_entry == nil || dns_entry.empty?
              dns_record = attrs[:private_ip]
            end
    
          when /Lb/
            dns_record = attrs[:dns_record]
          when /Cluster/
            dns_record = attrs[:shared_ip]
          end
        else
          # dns_record must be all lowercase
          dns_record.downcase!
          # unless ends w/ . or is an ip address
          dns_record += '.' unless dns_record =~ /,|\.$|^\d+\.\d+\.\d+\.\d+$/ || dns_record =~ Resolv::IPv6::Regex
        end
    
        if dns_record.empty?
          Chef::Log.error("cannot get dns_record value for: "+component.inspect)
          exit 1
        end
    
        if dns_record =~ /,/
          values.concat dns_record.split(",")
        else
          values.push(dns_record)
        end
      end
      return values
    end
        
    
    def verify(dns_name, dns_values, ns, max_retry_count=30)
      retry_count = 0
      dns_type = get_record_type(dns_name, dns_values)
  
      dns_values.each do |dns_value|
        if dns_value[-1,1] == '.'
          dns_value.chomp!('.')
        end
        
        verified = false
        while !verified && retry_count<max_retry_count do
          dns_lookup_name = dns_name
          if dns_name =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
            dns_lookup_name = $4 +'.' + $3 + '.' + $2 + '.' + $1 + '.in-addr.arpa'
          elsif dns_name =~ Resolv::IPv6::Regex
            dns_lookup_name = IPAddr.new(dns_name).reverse
          end
          
          puts "dig +short #{dns_type} #{dns_lookup_name} @#{ns}"
          existing_dns = `dig +short #{dns_type} #{dns_lookup_name} @#{ns}`.split("\n").map! { |v| v.gsub(/\.$/,"") }    
          Chef::Log.info("verify #{dns_name} has: "+dns_value)
          Chef::Log.info("ns #{ns} has: "+existing_dns.sort.to_s)
          verified = false
          existing_dns.each do |val|
            if val.downcase.include? dns_value
              verified = true
              Chef::Log.info("verified.")
            end
          end
          if !verified && max_retry_count > 1
            Chef::Log.info("waiting 10sec for #{ns} to get updated...")
            sleep 10
          end
          retry_count +=1
        end
        if !verified
          return false
        end       
      end
      return true
    end


    def ddns_execute(cmd_stmt)
      
      Chef::Log.info("cmd: #{cmd_stmt}")
      cmd_content = node.ddns_header + #{cmd_stmt}\nsend\n"
      cmd_file = node.ddns_key_file + '-cmd'
      File.open(cmd_file, 'w') { |file| file.write(cmd_content) }
      cmd = "nsupdate -k #{node.ddns_key_file} #{cmd_file}"
      puts cmd
      result = `#{cmd}`      
      if $?.to_i != 0 || result =~ /error/i
        fail_with_fault result
      end
      
    end
            
  end
end
