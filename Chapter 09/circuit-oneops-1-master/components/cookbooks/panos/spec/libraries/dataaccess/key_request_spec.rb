require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/key_request.rb', __FILE__)

describe 'Key Request' do

  before(:each) do
    @keyrequest = KeyRequest.new('url', 'userid','password')
  end

  context 'initialize' do
    it 'fails when userid is nil' do
      expect{KeyRequest.new('url', nil, 'password')}.to raise_error(ArgumentError)
    end

    it 'fails when password is nil' do
      expect{KeyRequest.new('url', 'userid', nil)}.to raise_error(ArgumentError)
    end

    it 'succeeds when userid and password are not nil' do
      key = KeyRequest.new('url', 'userid', 'password')
      expect{key}.to be_a KeyRequest
    end

    it 'fails when url is nil' do
      expect{KeyRequest.new(nil, 'userid', 'password')}.to raise_error(ArgumentError)
    end
  end

  context 'get key' do
    it 'returns a response' do
      response = "<response status = 'success'><result><key>mykey</key></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@keyrequest.get('url','username','password')}.to be_a Key
    end

    it 'returns an exception' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@keyrequest.get('url','user','password')}.to raise_error(Exception)
    end

    it 'returns an error' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@keyrequest.get('url','user','password')}.to raise_error(Exception)
    end
  end
end
