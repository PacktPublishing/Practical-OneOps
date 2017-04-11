require 'spec_helper'

require File.expand_path('../../../../libraries/models/panos_job.rb', __FILE__)

describe 'Panos Job' do
  context 'id' do
    it 'fails when nil' do
      expect{PanosJob.new(nil)}.to raise_error(ArgumentError)
    end

    it 'fails when not an Integer' do
      expect{PanosJob.new('hello')}.to raise_error(ArgumentError)
    end

    it 'succeeds when not nil and is an Integer' do
      job = PanosJob.new(25)
      expect{job}.to be_a PanosJob
    end
  end
end
