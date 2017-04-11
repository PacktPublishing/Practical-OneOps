require "chef/resource/deploy"

class Chef
  class Resource
    class Build < Chef::Resource::DeployRevision
      
      #provider_base Chef::Provider::DeployRevision
      
       def shallow_clone(arg=nil)
        set_or_return(
          :shallow_clone,
          arg,
          :kind_of => [ Integer ]
        )
      end
      
      def depth
        @shallow_clone ? @shallow_clone : nil
      end      
            
    end
  end
end

