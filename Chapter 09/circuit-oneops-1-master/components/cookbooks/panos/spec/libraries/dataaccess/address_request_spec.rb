require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/address_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Address Request' do

  before do
    key = Key.new('key')
    @addrequest = AddressRequest.new('url', key)
  end

  context 'initialize' do
    it 'fails when key is nil' do
      expect{AddressRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{AddressRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      expect{@addrequest}.to be_a AddressRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{AddressRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'update address' do
    it 'fails if the arguement is not an Address type' do
      expect{@addrequest.update('group-request')}.to raise_error(ArgumentError)
    end

    it 'throws an exception when there was an error from the firewall' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.update(addr)}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@addrequest.update(addr)}.to raise_error(Exception)
    end

    it 'succeeds when it updates the address for ip_netmask' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.update(addr)}.to_not raise_error
    end

    it 'succeeds when it updates the address for ip_range' do
      addr = Address.new('test', 'IP_RANGE', '1.1.1.1-1.1.1.10', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.update(addr)}.to_not raise_error
    end

    it 'succeeds when it updates the address for fqdn' do
      addr = Address.new('test', 'FQDN', 'hello.myname.is', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.update(addr)}.to_not raise_error
    end
  end
  
  context 'create address' do
    it 'succeeds when it creates the address for ip_netmask' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.create(addr)}.to_not raise_error
    end

    it 'succeeds when it creates the address for ip_range' do
      addr = Address.new('test', 'IP_RANGE', '1.1.1.1-1.1.1.10', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.create(addr)}.to_not raise_error
    end

    it 'succeeds when it creates the address for fqdn' do
      addr = Address.new('test', 'FQDN', 'hello.myname.is', 'group')
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.create(addr)}.to_not raise_error
    end

    it 'throws an exception when there was an error from the firewall' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.create(addr)}.to raise_error(Exception)
    end

    it 'fails if the arguement is not an Address type' do
      expect{@addrequest.create('group-request')}.to raise_error(ArgumentError)
    end

    it 'throws an exception making the rest call' do
      addr = Address.new('test', 'IP_NETMASK', '1.1.1.1', 'group')
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@addrequest.create(addr)}.to raise_error(Exception)
    end
  end
  
  context 'delete address' do
    it 'succeeds when it deletes the address' do
      response = "<response status = 'success'></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.delete('test', 'group')}.to_not raise_error
    end

    it 'throws an exception when there was an error from the firewall' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.delete('test', 'group')}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@addrequest.delete('test', 'group')}.to raise_error(Exception)
    end
  end
  
  context 'get all addresses with tag name' do
    it 'returns all the addresses with the tag name, expect 1 to return' do
      response = "<response status='success'><result><address><entry name='name' loc='group'><ip-netmask>1.1.1.1</ip-netmask><tag><member>tag</member></tag></entry><entry name='name2' loc='group'><ip-netmask>1.1.1.2</ip-netmask><tag><member>tag2</member></tag></entry></address></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      tag_array = @addrequest.get_all_for_tag('tag', 'group')
      expect{tag_array.length == 1}
    end

    it 'returns empty array for no addresses found with the tag name' do
      response = "<response status='success'><result><address><entry name='name' loc='group'><ip-netmask>1.1.1.1</ip-netmask><tag><member>tag3</member></tag></entry><entry name='name2' loc='group'><ip-netmask>1.1.1.2</ip-netmask></entry></address></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      tag_array = @addrequest.get_all_for_tag('tag', 'group')
      expect{tag_array.length == 0}
    end

    it 'returns array for addresses found from each type of address' do
      response = "<response status='success'><result><address><entry name='name' loc='group'><ip-netmask>1.1.1.1</ip-netmask><tag><member>tag</member></tag></entry><entry name='name2' loc='group'><ip-range>1.1.1.1-1.1.1.9</ip-range><tag><member>tag</member></tag></entry><entry name='name3' loc='group'><fqdn>1.1.1.1-1.1.1.9</fqdn><tag><member>tag</member></tag></entry></address></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      tag_array = @addrequest.get_all_for_tag('tag', 'group')
      expect{tag_array.length == 3}
    end

    it 'throws an exception when there was an error from the firewall' do
      response = "<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>"
      allow(RestClient::Request).to receive(:execute).and_return(response)
      expect{@addrequest.get_all_for_tag('tag', 'group')}.to raise_error(Exception)
    end

    it 'throws an exception making the rest call' do
      allow(RestClient::Request).to receive(:execute).and_raise(Exception)
      expect{@addrequest.get_all_for_tag('tag', 'group')}.to raise_error(Exception)
    end
  end
  
end
