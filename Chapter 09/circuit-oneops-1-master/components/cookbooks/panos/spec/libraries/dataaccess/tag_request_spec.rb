require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/tag_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Tag Request' do

  before do
    key = Key.new('key')
    @tagrequest = TagRequest.new('url', key)
  end

  context 'initialize' do
    it 'fails when key is nil' do
      expect{TagRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{TagRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      expect{@tagrequest}.to be_a TagRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{TagRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'create tag' do
    it 'succeeds when it creates the tag' do
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@tagrequest.create('name','group')}.to_not raise_error
    end

    it 'throws an exception when there was an error from the firewall' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@tagrequest.create('name','group')}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@tagrequest.create('name','group')}.to raise_error(Exception)
    end
  end
  
end
