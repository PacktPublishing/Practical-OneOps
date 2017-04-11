# rubocop:disable MethodLength
# rubocop:disable AbcSize
# rubocop:disable ClassLength
# rubocop:disable LineLength
module AzureDns
  require 'chef'
  require 'rest-client'
  # Cookbook Name:: azuredns
  # Recipe:: set_dns_records
  #
  # This class handles following dns recordset operations
  # a) set dns recordset
  # b) get dns recordset
  # c) remove DNS recordset
  #
  class RecordSet
    def initialize(dns_attributes, token, platform_resource_group)
      @subscription = dns_attributes['subscription']
      @dns_resource_group = platform_resource_group
      @zone = dns_attributes['zone']
      @token = token
    end

    def get_existing_records_for_recordset(record_type, record_set_name)
      # construct the URL to get the records from the dns zone
      resource_url = "https://management.azure.com/subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}/#{record_type}/#{record_set_name}?api-version=2015-05-04-preview"
      Chef::Log.info("AzureDns::RecordSet - Resource URL is: #{resource_url}")
      begin
        existing_records = []
        dns_response = RestClient.get(
          resource_url,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token
        )
      rescue RestClient::Exception => e
        if e.http_code == 404
          Chef::Log.info('AzureDns::RecordSet - 404 code, record set does not exist.  returning empty array')
          return existing_records
        else
          msg = "Exception trying to get existing #{record_type} records for the record set: #{record_set_name}"
          puts "***FAULT:FATAL=#{msg}"
          Chef::Log.error("AzureDns::RecordSet - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
        end
      end
      Chef::Log.info("AzureDns::RecordSet - Getting #{record_type} record response is: #{dns_response}")
      begin
        dns_hash = JSON.parse(dns_response)
        # get existing records on the record set
        case record_type
        when 'A'
          dns_hash['properties']['ARecords'].each do |record|
            Chef::Log.info("AzureDns:RecordSet - A record is: #{record}")
            existing_records.push(record['ipv4Address'])
          end
        when 'CNAME'
          cname_record = dns_hash['properties']['CNAMERecord']
          if !cname_record.nil?
            Chef::Log.info("AzureDns:RecordSet - CNAME record is: #{dns_hash['properties']['CNAMERecord']['cname']}")
            existing_records.push(dns_hash['properties']['CNAMERecord']['cname'])
          end
        end
        existing_records
      rescue => e
        msg = "Exception trying to parse response: #{dns_response}"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("AzureDns::RecordSet - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

    def set_records_on_record_set(record_set_name, records, record_type, ttl)
      # construct the URL to get the records from the dns zone
      resource_url = "https://management.azure.com/subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}/#{record_type}/#{record_set_name}?api-version=2015-05-04-preview"
      Chef::Log.info("AzureDns::RecordSet - Resource URL is: #{resource_url}")
      case record_type
      when 'A'
        arecords_array = []
        records.each do |ip|
          arecords_array.push('ipv4Address' => ip)
        end
        body = {
          location: 'global',
          tags: '',
          properties: {
            TTL: ttl,
            ARecords: arecords_array
          }
        }
      when 'CNAME'
        body = {
          location: 'global',
          tags: '',
          properties: {
            TTL: ttl,
            CNAMERecord: {
              'cname' => records.first # because cname only has 1 value and we know the object is an array passed in.
            }
          }
        }
      end

      Chef::Log.info("Body is: #{body}")
      begin
        dns_response = RestClient.put(
          resource_url,
          body.to_json,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token
        )
        Chef::Log.info("AzureDns::RecordSet - Create/Update response is: #{dns_response}")
      rescue RestClient::Exception => e
        msg = "Exception setting #{record_type} records for the record set: #{record_set_name}"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("AzureDns::RecordSet - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

    def remove_record_set(record_set_name, record_type)
      # construct the URL to get the records from the dns zone
      resource_url = "https://management.azure.com/subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}/#{record_type}/#{record_set_name}?api-version=2015-05-04-preview"
      Chef::Log.info("AzureDns::RecordSet - Resource URL is: #{resource_url}")
      begin
        dns_response = RestClient.delete(
          resource_url,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token
        )
        Chef::Log.info("AzureDns::RecordSet - Deleting #{record_type} record response is: #{dns_response}")
      rescue RestClient::Exception => e
        if e.http_code == 404
          Chef::Log.info('AzureDns::RecordSet - 404 code, trying to delete something that is not there.')
        else
          msg = "Exception trying to remove #{record_type} records for the record set: #{record_set_name}"
          puts "***FAULT:FATAL=#{msg}"
          Chef::Log.error("AzureDns::RecordSet - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
        end
      end
    end
  end
end
