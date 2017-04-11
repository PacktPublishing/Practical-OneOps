#!/bin/bash
#
# Install ruby and bundle for chef or puppet, oneops user, sshd config
#
set -e

if ! [ -e /etc/ssh/ssh_host_dsa_key ] ; then
  echo "generating host ssh keys"
  /usr/bin/ssh-keygen -A
fi

for ARG in "$@"
do
  # if arg starts with http then use it to set http_proxy env variable
  if [[ $ARG == http:* ]] ; then
	http_proxy=${ARG/http:/}
    echo "exporting http_proxy=$http_proxy"
    export http_proxy=$http_proxy
  elif [[ $ARG == https:* ]] ; then
	https_proxy=${ARG/https:/}
    echo "exporting https_proxy=$https_proxy"
    export https_proxy=$https_proxy
  elif [[ $ARG == no:* ]] ; then
	no_proxy=${ARG/no:/}
    echo "exporting no_proxy=$no_proxy"
    export no_proxy=$no_proxy
  elif [[ $ARG == rubygems:* ]] ; then
    rubygems_proxy=${ARG/rubygems:/}
    echo "exporting rubygems_proxy=$rubygems_proxy"
    export rubygems_proxy=$rubygems_proxy
  elif [[ $ARG == misc:* ]] ; then
    misc_proxy=${ARG/misc:/}
    echo "exporting misc_proxy=$misc_proxy"
    export misc_proxy=$misc_proxy
  fi
done

# setup os release variables
echo "Install ruby and bundle."

# sles or opensuse
if [ -e /etc/SuSE-release ] ; then
  zypper -n in sudo rsync file make gcc glibc-devel libgcc ruby ruby-devel rubygems libxml2-devel libxslt-devel perl
  zypper -n in rubygem-yajl-ruby

  # sles
  hostname=`cat /etc/HOSTNAME`
  grep $hostname /etc/hosts
  if [ $? != 0 ]; then
    ip_addr=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/' | xargs`
    echo "$ip_addr $hostname" >> /etc/hosts
  fi

# redhat / centos
elif [ -e /etc/redhat-release ] ; then
  echo "installing ruby, libs, headers and gcc"
  yum -d0 -e0 -y install sudo file make gcc gcc-c++ glibc-devel libgcc ruby ruby-libs ruby-devel libxml2-devel libxslt-devel ruby-rdoc rubygems perl perl-Digest-MD5 nagios nagios-devel nagios-plugins

  # disable selinux
  if [ -e /selinux/enforce ]; then
    echo 0 >/selinux/enforce
    echo "SELINUX=disabled" >/etc/selinux/config
	echo "SELINUXTYPE=targeted" >>/etc/selinux/config
  fi

  # allow ssh sudo's w/out tty
  grep -v requiretty /etc/sudoers > /etc/sudoers.t
  mv -f /etc/sudoers.t /etc/sudoers
  chmod 440 /etc/sudoers

else
# debian
	export DEBIAN_FRONTEND=noninteractive
	echo "apt-get update ..."
	apt-get update >/dev/null 2>&1
	if [ $? != 0 ]; then
	   echo "apt-get update returned non-zero result code. Usually means some repo is returning a 403 Forbidden. Try deleting the compute from providers console and retrying."
	   exit 1
	fi
	apt-get install -q -y build-essential make libxml2-dev libxslt-dev libz-dev ruby ruby-dev nagios3
	
	# seperate rubygems - rackspace 14.04 needs it, aws doesn't
	set +e
	apt-get -y -q install rubygems-integration
	rm -fr /etc/apache2/conf.d/nagios3.conf
	set -e
fi

me=`logname`
base_path="/home/$me"

if [ "$me" == "root" ] ; then
  base_path="/root"
fi
local_gems="$base_path/shared/cookbooks/vendor/cache/"

set +e
gem source | grep $local_gems
if [ $? != 0 ]; then
  gem source --add file://$local_gems
  gem source --remove 'http://rubygems.org/'
  gem source
fi

if [ -n "$rubygems_proxy" ]; then
  proxy_exists=`gem source | grep $rubygems_proxy | wc -l`
  if [ $proxy_exists == 0 ] ; then
    gem source --remove $rubygems_proxy
    gem source --remove 'http://rubygems.org/'
    gem source --remove 'https://rubygems.org/'
    gem source
  fi
else
  rubygems_proxy="https://rubygems.org"
fi

cd $local_gems

if [ -e /etc/redhat-release ] ; then
	# needed for rhel >= 7
	gem update --system 1.8.25
   if [ $? -ne 0 ]; then
     gem source --remove file://$local_gems
     gem source --add $rubygems_proxy
     set -e
     gem update --system 1.8.25
     set +e
   fi	
fi

gem_version="1.7.7"
grep 16.04 /etc/issue
if [ $? -eq 0 ]
then
  gem_version="2.0.2"
fi

gem install json --version $gem_version --no-ri --no-rdoc
if [ $? -ne 0 ]; then
    echo "gem install using local repo failed. reverting to rubygems proxy."
    gem source --add $rubygems_proxy
    gem source --remove file://$local_gems
    gem source --remove 'http://rubygems.org/'
    gem source
    gem install json --version $gem_version --no-ri --no-rdoc
    if [ $? -ne 0 ]; then
      echo "could not install json gem"
      exit 1
    fi
fi

set -e
gem install bundler --bindir /usr/bin --no-ri --no-rdoc

mkdir -p /opt/oneops
echo "$rubygems_proxy" > /opt/oneops/rubygems_proxy

set +e
perl -p -i -e 's/ 00:00:00.000000000Z//' /var/lib/gems/*/specifications/*.gemspec 2>/dev/null

# oneops user
grep "^oneops:" /etc/passwd 2>/dev/null
if [ $? != 0 ] ; then
    set -e
	echo "*** ADD oneops USER ***"

	# create oneops user & group - deb systems use addgroup
	if [ -e /etc/lsb-release] ] ; then
		addgroup oneops
	else
		groupadd oneops
	fi

	useradd oneops -g oneops -m -s /bin/bash
	echo "oneops   ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
else
	echo "oneops user already there..."
fi
set -e

# ssh and components move
if [ "$me" == "oneops" ] ; then
  exit
fi

echo "copying files from provider-setup user $me to oneops..."

home_dir="/home/$me"
if [ "$me" == "root" ] ; then
  cd /root
  home_dir="/root"
else
  cd /home/$me
fi

me_group=$me
if [ -e /etc/SuSE-release ] ; then
  me_group="users"
fi

pwd
# gets rid of the 'only use ec2-user' ssh response
sed -e 's/.* ssh-rsa/ssh-rsa/' .ssh/authorized_keys > .ssh/authorized_keys_
mv .ssh/authorized_keys_ .ssh/authorized_keys
chown $me:$me_group .ssh/authorized_keys
chmod 600 .ssh/authorized_keys

# ibm rhel
if [ "$me" != "root" ] ; then
  `rsync -a /home/$me/.ssh /home/oneops/`
else
  `cp -r ~/.ssh /home/oneops/.ssh`
  `cp ~/.ssh/authorized_keys /home/oneops/.ssh/authorized_keys`
fi

if [ "$me" == "idcuser" ] ; then
  echo 0 > /selinux/enforce
  # need to set a password for the rhel 6.3
  openssl rand -base64 12 | passwd oneops --stdin
fi

mkdir -p /opt/oneops/workorder /etc/nagios/conf.d /var/log/nagios
rsync -a $home_dir/circuit-oneops-1 /home/oneops/
rsync -a $home_dir/shared /home/oneops/
chown -R oneops:oneops /home/oneops /opt/oneops
