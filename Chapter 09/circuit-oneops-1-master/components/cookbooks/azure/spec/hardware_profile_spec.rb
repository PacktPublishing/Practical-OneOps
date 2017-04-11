require 'spec_helper'
require 'azure_mgmt_compute'

require File.expand_path('../../libraries/hardware_profile.rb', __FILE__)

describe AzureCompute::HardwareProfile do
  describe '#build_profile' do
    context 'when vm_size is not nil' do
      it 'returns the profile with vm_size set' do
        profile = AzureCompute::HardwareProfile.new()
        hwprofile = profile.build_profile('Standard_A01')
        expect(hwprofile.vm_size).to eq 'Standard_A01'
      end
    end

    context 'when vm_size is nil' do
      it 'throws an exception that the size is required' do
        profile = AzureCompute::HardwareProfile.new()
        expect { profile.build_profile(nil) }.to raise_exception(Exception)
      end
    end
  end
end