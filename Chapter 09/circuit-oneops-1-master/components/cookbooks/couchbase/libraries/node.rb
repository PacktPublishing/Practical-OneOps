class Chef::Recipe::Node
  attr_accessor :ip_address, :action

  def initialize(ip_address, action)
    # Instance variables
    @ip_address = ip_address
    @action = action
  end
end
