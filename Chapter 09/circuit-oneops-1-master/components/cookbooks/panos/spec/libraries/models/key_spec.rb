require 'spec_helper'

require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Key' do
  context 'value' do
    it 'succeeds when not nil' do
      key = Key.new('key')
      expect{key}.to be_a Key
    end

    it 'fails when nil' do
      expect{Key.new(nil)}.to raise_error(ArgumentError)
    end
  end
end
