# trust_pub_keys - Trust all public keys in this deployment
#
# This recipe adds all public keys created for this deployment
# to the authorized_keys file for the oneops user.  This is
# necessary to allow cross-cloud operations to work properly in
# a multi-cloud environment.

require File.expand_path("../spark_helper.rb", __FILE__)

cache_path = Chef::Config[:file_cache_path]

sparkInfo = get_spark_info()
configNode = sparkInfo[:config_node]

# In order to ensure that all computes in this deployment can be accessed
# across clouds, make sure that the public keys for all generated keys
# are in the authorized_keys file for the oneops user.
sparkKeys = nil

if node.workorder.payLoad.has_key?("sparkKeys")
  Chef::Log.debug("sparkKeys:  public keys found!")
  sparkKeys = node.workorder.payLoad.sparkKeys
else
  Chef::Log.debug("sparkKeys:  No public keys found!")
end

if sparkKeys != nil
  # Find the current public key.  This is already in the authorized_keys file
  currentKey = node.workorder.payLoad.SecuredBy[0][:ciAttributes][:public]

  # Go through all of the public keys. Grep for the key in the authorized_keys
  # file and add it if it is not present
  sparkKeys.each do |sparkKey|
    thisCloudId = cloudid_from_name(sparkKey.ciName)

    # In the ci attributes, the public key has a newline at the end
    # Strip it off before proceeding
    checkKey = sparkKey[:ciAttributes][:public].strip

    bash "check_key_#{thisCloudId}" do
      code <<-EOS
        GREP_CHECK=`grep -c "#{checkKey}" /home/oneops/.ssh/authorized_keys`
        if [ "$GREP_CHECK" = "0" ]; then
          echo "#{checkKey}" >> /home/oneops/.ssh/authorized_keys
        fi
      EOS
    end
  end
end
