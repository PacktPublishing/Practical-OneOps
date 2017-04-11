require 'spec_helper'

require File.expand_path('../../../../libraries/models/address_group.rb', __FILE__)

describe 'Address Group' do
  context 'name' do
    it 'succeeds when not nil' do
      address_group = AddressGroup.new('name', 'Static', 'OneOps', 'group', 'tag')
      expect{address_group}.to be_a AddressGroup
    end

    it 'fails when nil' do
      expect{AddressGroup.new(nil, 'Dynamic', 'OneOps', 'group', 'tag')}.to raise_error(ArgumentError)
    end
  end

  context 'type' do
    it 'fails when nil' do
      expect{AddressGroup.new('name', nil, 'OneOps', 'group', 'tag')}.to raise_error(ArgumentError)
    end

    it 'fails when not valid' do
      %w(OH_MAN FAIL).each do |type|
        expect{AddressGroup.new('name', type, 'OneOps', 'group', 'tag')}.to raise_error(ArgumentError)
      end
    end
  end

  context 'criteria' do
    it 'succeeds when not nil' do
      address_group = AddressGroup.new('name', 'Dynamic', 'OneOps', 'group', 'tag')
      expect{address_group}.to be_a AddressGroup
    end

    it 'fails when nil' do
      expect{AddressGroup.new('name', 'Static', nil, 'group', 'tag')}.to raise_error(ArgumentError)
    end
  end

  context 'device groups' do
    it 'fails when nil' do
      expect{AddressGroup.new('name', 'Static', 'criteria', nil, 'tag')}.to raise_error(ArgumentError)
    end
  end
end
