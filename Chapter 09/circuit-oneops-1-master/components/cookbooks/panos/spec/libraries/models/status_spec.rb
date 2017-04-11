require 'spec_helper'

require File.expand_path('../../../../libraries/models/status.rb', __FILE__)

describe 'Status' do
  context 'status' do
    it 'succeeds when not nil' do
      status = Status.new('status', 'result', 100)
      expect{status}.to be_a Status
    end

    it 'fails when nil' do
      expect{Status.new(nil, 'result', 100)}.to raise_error(ArgumentError)
    end
  end

  context 'result' do
    it 'succeeds when not nil' do
      status = Status.new('status', 'result', 100)
      expect{status}.to be_a Status
    end

    it 'fails when nil' do
      expect{Status.new('status', nil, 100)}.to raise_error(ArgumentError)
    end
  end

  context 'progress' do
    it 'fails when nil' do
      expect{Status.new('status', 'result', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when not an Integer' do
      expect{Status.new('status', 'result', 'hello')}.to raise_error(ArgumentError)
    end

    it 'succeeds when not nil and is an Integer' do
      status = Status.new('status', 'result', 100)
      expect{status}.to be_a Status
    end
  end
end
