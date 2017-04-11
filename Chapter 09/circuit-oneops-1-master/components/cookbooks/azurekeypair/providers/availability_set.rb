
def whyrun_supported?
  true
end

action :create do
  as_manager = AzureBase::AvailabilitySetManager.new(@new_resource.node)
  as_manager.add()

  @new_resource.updated_by_last_action(true)
end