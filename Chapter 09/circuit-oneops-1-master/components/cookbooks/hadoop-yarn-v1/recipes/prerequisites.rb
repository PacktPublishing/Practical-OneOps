#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: prerequisites
#
#

# set system-wide JAVA_HOME
cookbook_file '/etc/profile.d/java.sh' do
    source 'java.sh'
    owner 'root'
    group 'root'
    mode '0755'
end

# a system is not a system without screen, mosh and htop
package 'screen'
package 'mosh'
package 'htop'

# install process management utils
package 'psmisc'

# support for parsing xml
package 'xmlstarlet'
