require File.expand_path('../../models/key.rb', __FILE__)
require File.expand_path('../../models/panos_job.rb', __FILE__)

class CommitRequest

  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' unless key.is_a? Key

    @baseurl = url
    @key = key
  end

  def commit_configs(device_group)
    begin
    	commit_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'commit',
            :action => 'all',
    				:cmd => "<commit-all><shared-policy><device-group><entry name=\"#{device_group}\"/></device-group></shared-policy></commit-all>"
    			}
    		}
    	)
      commit_hash = Crack::XML.parse(commit_response)
      Chef::Log.info("commit_hash is: #{commit_hash}")
      if commit_hash['response']['status'] == 'error'
        Chef::Log.info("Error Code is: #{commit_hash['response']['code']}")
        if commit_hash['response']['code'].to_i == 13
          # a commit is already in progress, need to sleep and try again
          Chef::Log.info('Sleeping 30 seconds and trying commit again...')
          sleep(30)
          commit_configs(device_group)
        else
          raise Exception.new("PANOS Error committing: #{commit_hash['response']['msg']}")
        end
      end

      if commit_hash['response'].has_key?('result')
        # if job exists in the payload that means a job was submitted to commit the changes.
        if !commit_hash['response']['result'].nil? && commit_hash['response']['result'].has_key?('job')
          job = PanosJob.new(commit_hash['response']['result']['job'].to_i)
          Chef::Log.info("PANOS Jobid is: #{job}")
          return job
        else
          return nil
        end
      else
        return nil
      end
    rescue => e
      raise Exception.new("Exception committing PANOS job: #{e}")
    end
  end

end
