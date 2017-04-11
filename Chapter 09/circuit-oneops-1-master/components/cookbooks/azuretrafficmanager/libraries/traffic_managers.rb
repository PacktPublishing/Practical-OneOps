require File.expand_path('../../libraries/model/traffic_manager.rb', __FILE__)

class TrafficManagers

  URL_MGMT =  'https://management.azure.com/'
  API_VERSION = '2015-04-28-preview'

  def initialize(resource_group, profile_name, subscription, traffic_manager = nil, azure_token)
    fail ArgumentError, 'resource_group is nil' if resource_group.nil?
    fail ArgumentError, 'profile_name is nil' if profile_name.nil?
    fail ArgumentError, 'subscription is nil' if subscription.nil?

    @traffic_manager = traffic_manager
    @resource_url = URL_MGMT + '/subscriptions/' + subscription + '/resourceGroups/' + resource_group + '/providers/Microsoft.Network/trafficManagerProfiles/' + profile_name + '?api-version=' + API_VERSION
    @azure_token = azure_token
  end

  def create_update_profile
    payload = @traffic_manager.serialize_object
      begin
        response = RestClient.put(
            @resource_url,
            payload.to_json,
            {
                :accept => :json,
                :content_type => :json,
                :authorization => @azure_token
            }
        )
      rescue => e
        Chef::Log.warn("Response traffic_manager create_update_profile status code - #{e.response.code}")
        Chef::Log.warn("Response - #{e.response}")
        return e.response.code
      end
    Chef::Log.info("Response traffic_manager create_update_profile status code - #{response.code}")
    Chef::Log.info("Response - #{response}")
    return response.code
  end

  def delete_profile
    status_code = get_profile
    if status_code == 200
        begin
          response = RestClient.delete(
              @resource_url,
              {
                  :accept => :json,
                  :content_type => :json,
                  :authorization => @azure_token
              }
          )
        rescue => e
          Chef::Log.warn("ERROR traffic_manager delete_profile status code - #{e.response.code}")
          Chef::Log.warn("ERROR - #{e.response}")
          return e.response.code
        end
      Chef::Log.info("Response traffic_manager delete_profile status code - #{response.code}")
      Chef::Log.info("Response - #{response}")
      return response.code
    end
    return status_code
  end

  def get_profile
    begin
      response = RestClient.get(
          @resource_url,
          {
              :accept => :json,
              :content_type => :json,
              :authorization => @azure_token
          }
      )
    rescue => e
      Chef::Log.warn("Response traffic_manager get_profile status code - #{e.response.code}")
      Chef::Log.warn("Response - #{e.response}")
      return e.response.code
    end
    Chef::Log.info("Response traffic_manager get_profile status code - #{response.code}")
    Chef::Log.info("Response - #{response}")
    return response.code
  end

end
