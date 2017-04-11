actions :install, :remove, :install_file, :run
default_action :install if defined?(default_action) # Chef > 10.8

# Default action for Chef <= 10.8
def initialize(*args)
  super
  @action = :install
end

attribute :name, :kind_of => String, :name_attribute => true
attribute :version, :default => nil
attribute :timeout, :default => 900
attribute :environment, :kind_of => Hash, :default => {}