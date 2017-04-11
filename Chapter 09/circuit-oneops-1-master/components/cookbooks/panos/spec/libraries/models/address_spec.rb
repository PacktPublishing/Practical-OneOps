require 'spec_helper'

require File.expand_path('../../../../libraries/models/address.rb', __FILE__)

describe 'Address' do
  it 'succeeds when type is IP_NETMASK and all is well' do
    address = Address.new('name', 'IP_NETMASK', '1.1.1.1', 'group', 'tag')
    expect{address}.to be_a Address
  end

  it 'succeeds when type is IP_RANGE and all is well' do
    address = Address.new('name', 'IP_RANGE', '1.1.1.1-1.1.1.10', 'group', 'tag')
    expect{address}.to be_a Address
  end

  it 'succeeds when type is FQDN and all is well' do
    address = Address.new('name', 'FQDN', '1.1.1.1', 'group', 'tag')
    expect{address}.to be_a Address
  end

  context 'name' do
    it 'fails when nil' do
      expect{Address.new(nil, 'IP_NETMASK', '0000:0000:0000:0000:0000:0000:0000:0000', 'group', 'tag')}.to raise_error(ArgumentError)
    end
  end

  context 'type' do
    it 'fails when nil' do
      expect{Address.new('name', nil, '1.1.1.1', 'group', 'tag')}.to raise_error(ArgumentError)
    end

    it 'fails when not valid' do
      %w(OH_MAN DANG_IT FAIL).each do |type|
        expect{Address.new('name', type, '1.1.1.1', 'group', 'tag')}.to raise_error(ArgumentError)
      end
    end
  end

  context 'ip address' do
    it 'fails when nil' do
      expect{Address.new('name', 'IP_RANGE', nil, 'group', 'tag')}.to raise_error(ArgumentError)
    end

    it 'fails if not ipv4 format' do
      expect{Address.new('name', 'IP_NETMASK', '1.2', 'group', 'tag')}.to raise_error(ArgumentError)
    end
  end

  context 'device group' do
    it 'fails when nil' do
      expect{Address.new('name', 'IP_NETMASK', '1.2.3.4', nil, 'tag')}.to raise_error(ArgumentError)
    end
  end
end
