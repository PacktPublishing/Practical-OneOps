# Class to handle the hardware profile for the azure compute.
# Nothing much happening here, just setting the vm size on the hardware profile for now.
module AzureCompute
  class HardwareProfile

    def build_profile(vm_size)
      # vm_size is required for the overall creation of the VM, so we will check here and make sure we throw an exception
      # that it isn't present.
      OOLog.fatal('vm_size cannot be nil.  It is required!') if vm_size.nil?

      hardware_profile = Azure::ARM::Compute::Models::HardwareProfile.new
      hardware_profile.vm_size = vm_size
      hardware_profile
    end

  end
end
