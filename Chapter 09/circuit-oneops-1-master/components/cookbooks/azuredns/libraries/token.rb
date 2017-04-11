require 'chef'
require ::File.expand_path('../../../azure/constants', __FILE__)

# **Rubocop Suppression**
# rubocop:disable LineLength
# rubocop:disable MethodLength

module AzureDns
  # DNS Auth Token Class
  class Token
    def initialize(tenant_id, client_id, client_secret, http_proxy = nil)
      @tenant_id = tenant_id
      @client_id = client_id
      @client_secret = client_secret
      @http_proxy = http_proxy
    end

    def generate_token
      login_url = "#{AZURE_LOGIN_URL}#{@tenant_id}/oauth2/token"
      unless @http_proxy.nil?
        Chef::Log.info("azuredns:get_azure_token.rb - Setting proxy on RestClient for calls to Azure: #{@http_proxy}")
        RestClient.proxy = @http_proxy
      end

      begin
        token_response = RestClient.post(
          login_url,
          client_id: @client_id,
          client_secret: @client_secret,
          grant_type: AZURE_GRANT_TYPE,
          resource: AZURE_RESOURCE
        )
        token = 'Bearer ' + JSON.parse(token_response)['access_token']
        return token
      rescue => e
        msg = 'Exception trying to retrieve the token.'
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("azuredns::get_azure_token.rb - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
  end
end
