module Couchbase
  class CouchbaseREST

    @ip
    @username
    @password

    def initialize(ip, username, password)
      @ip = ip
      @username = username
      @password = password
    end

    def autofailover

      response = get_request "/settings/autoFailover"

      JSON.parse response.body

    end

    def set_autofailover(enabled, timeout)
      post_request "/settings/autoFailover", "enabled=#{enabled}&timeout=#{timeout}"
      sleep 0.1
      return autofailover
    end

    def reset_quota

      post_request "/settings/autoFailover/resetCount"

    end

    def alerts

      response = get_request "/settings/alerts"

      JSON.parse response.body

    end

    def cluster_details

      # Using waitChange to return "balanced" and "failoverWarnings" attributes
      response = get_request "/pools/default?waitChange=1"

      JSON.parse response.body

    end

    def bucket_info(name)

      if name != nil && !name.empty?

        response = get_request "/pools/default/buckets/#{name}"

        JSON.parse response.body

      end

    end

    def tasks
      response = get_request "/pools/default/tasks"
      JSON.parse response.body 
    end
    
    private

    def get_request(path)

      uri = URI("http://#{@ip}:8091#{path}")

      request = Net::HTTP::Get.new(uri.request_uri)

      http_request request, uri

    end

    def post_request(path, body = nil)

      uri = URI("http://#{@ip}:8091#{path}")

      request = Net::HTTP::Post.new(uri.request_uri)

      if body != nil
        request.body = body
      end

      http_request request, uri

    end

    def http_request(request, uri)

      request.basic_auth @username, @password

      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request request
      end

      if !response.code == 200
        raise response.msg
      end

      response

    end

  end
end
