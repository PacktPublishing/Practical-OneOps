# Prerequisites - Install basic system packages
#
# This recipe ensures that a number of basic packages are installed in each VM.
#

Chef::Log.info("Running #{node['app_name']}::prerequisites")

# a system is not a system without screen, mosh and htop
package 'screen'
package 'mosh'
package 'htop'

# install process management utils
package 'psmisc'
