require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/address_group_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)
require File.expand_path('../../../../libraries/models/address_group.rb', __FILE__)
require File.expand_path('../../../../libraries/models/address.rb', __FILE__)

describe 'Address Group Request' do

  before do
    key = Key.new('key')
    @agrequest = AddressGroupRequest.new('url', key)
  end

  context 'initialize' do
    it 'fails when key is nil' do
      expect{AddressGroupRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{AddressGroupRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      expect{@agrequest}.to be_a AddressGroupRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{AddressGroupRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'create dynamic address group' do
    it 'succeeds when it creates the group' do
      ag = AddressGroup.new('test', 'Dynamic', 'criteria', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@agrequest.create(ag)}.to_not raise_error
    end

    it 'throws an exception when there was an error from the firewall' do
      ag = AddressGroup.new('test', 'Dynamic', 'criteria', 'group')
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@agrequest.create(ag)}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      ag = AddressGroup.new('test', 'Dynamic', 'criteria', 'group')
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@agrequest.create(ag)}.to raise_error(Exception)
    end

    it 'throws an arguement error when the address group is not the correct type' do
      expect{@agrequest.create('group-request')}.to raise_error(ArgumentError)
    end

    it 'fails when static and no Address is passed in' do
      ag = AddressGroup.new('test', 'Static', 'criteria', 'group')
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@agrequest.create(ag)}.to raise_error(Exception)
    end

    it 'fails when static and the address passed in is not an Address type' do
      ag = AddressGroup.new('test', 'Static', 'criteria', 'group')
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@agrequest.create(ag, 'NotAnAddress')}.to raise_error(Exception)
    end

    it 'succeeds when static' do
      ag = AddressGroup.new('test', 'Static', 'criteria', 'group')
      address = Address.new('name', 'IP_NETMASK', '1.1.1.1', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@agrequest.create(ag, address)}.to_not raise_error
    end

  end
  
  context 'delete group' do
    it 'succeeds when it deletes the group' do
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@agrequest.delete('test', 'group')}.to_not raise_error
    end

    it 'throws an exception when there was an error from the firewall' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@agrequest.delete('test', 'group')}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@agrequest.delete('test', 'group')}.to raise_error(Exception)
    end

  end
  
end
