require 'chef'
require ::File.expand_path('../../../azure/constants', __FILE__)

# **Rubocop Suppression**
# rubocop:disable MethodLength
# rubocop:disable LineLength
# rubocop:disable AbcSize

module AzureDns
  # DNS Zone Class
  class Zone
    def initialize(dns_attributes, token, platform_resource_group)
      @subscription = dns_attributes['subscription']
      @dns_resource_group = platform_resource_group
      @zone = dns_attributes['zone']
      @token = token
    end

    def check_for_zone
      # construct the URL to get the records from the dns zone
      resource_url = "#{AZURE_RESOURCE}subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}?api-version=2015-05-04-preview"
      puts "AzureDns:Zone - Resource URL is: #{resource_url}"
      begin
        dns_response = RestClient.get(
          resource_url,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token
        )
        puts dns_response
        dns_hash = JSON.parse(dns_response)
        if dns_hash.key?('id') && !dns_hash['id'].nil?
          puts 'AzureDns:Zone - Zone Exists, no need to create'
        end

        true
      rescue RestClient::Exception => e
        if e.http_code == 404
          puts('AzureDns:Zone - 404 code, Zone does not exist.  Need to create')
          false
        else
          msg = "Exception checking if the zone exists: #{@zone}"
          puts "***FAULT:FATAL=#{msg}"
          Chef::Log.error("AzureDns:Zone - Excpetion is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
        end
      end
    end

    def create
      # construct the URL to get the records from the dns zone
      resource_url = "#{AZURE_RESOURCE}subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}?api-version=2015-05-04-preview"
      puts "AzureDns:Zone - Resource URL is: #{resource_url}"
      body = {
        location: 'global',
        tags: {},
        properties: {} }
      begin
        dns_response = RestClient.put(
          resource_url,
          body.to_json,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token)
        puts dns_response
      rescue => e
        msg = "Exception creating zone: #{@zone}"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("AzureDns:Zone - Excpetion is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
  end
end
