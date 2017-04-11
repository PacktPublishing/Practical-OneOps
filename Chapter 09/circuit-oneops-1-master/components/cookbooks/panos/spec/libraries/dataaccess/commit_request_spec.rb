require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/commit_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Commit Request' do

  before do
    key = Key.new('key')
    @commitrequest = CommitRequest.new('url', key)
  end

  context 'initialize' do
    it 'fails when key is nil' do
      expect{CommitRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{CommitRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      expect{@commitrequest}.to be_a CommitRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{CommitRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'commit configs' do
    it 'returns a valid job object' do
      response = "<response status='success'><result><job>1</job></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      job = @commitrequest.commit_configs('group')
      expect{job.is_a?(Job)}
    end

    it 'returns nil if no result' do
      response = "<response status='success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      job = @commitrequest.commit_configs('group')
      expect{job.nil?}
    end

    it 'returns nil if no job in the result' do
      response = "<response status='success'><result></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      job = @commitrequest.commit_configs('group')
      expect{job.nil?}
    end

    it 'throws an exception when there was an error from the firewall' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@commitrequest.commit_configs('group')}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@commitrequest.commit_configs('group')}.to raise_error(Exception)
    end
  end
end
