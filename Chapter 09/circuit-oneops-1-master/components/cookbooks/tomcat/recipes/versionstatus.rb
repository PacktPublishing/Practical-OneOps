check_version_script=<<-"EOF"
RETVAL="0"
WEBAPP_DIR=#{node['tomcat']['webapp_install_dir']}

echo $WEBAPP_DIR
PROC_PID=`pgrep -f "org.apache.catalina.startup.Bootstrap"`
PROC_LOC="/proc/$PROC_PID"

echo "Location of proc:  $PROC_LOC"
pidtime=`stat -c %Y $PROC_LOC`

echo $pidtime
# get latest modified file

files=`cd $WEBAPP_DIR; ls`
echo $files

# Get the location
for file in $files; do

  fileloc=`readlink -f $WEBAPP_DIR/$file`
  echo $fileloc

  filetime=`stat -c %Y $fileloc`
  echo $filetime

  if [[ "$pidtime" -lt "$filetime" ]]; then
    echo "Tomcat not restarted after app($fileloc) is deployed"
    RETVAL="1"
  fi
done
echo $RETVAL
EOF
node.set[:versioncheckscript]=check_version_script