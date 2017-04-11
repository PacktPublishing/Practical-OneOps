#!/bin/bash

echo "In order to run beeline, run the following:"
echo
echo "/opt/spark/bin/beeline"
echo
echo "And at the prompt enter:"
echo
echo "!connect jdbc:hive2://`hostname --fqdn`:10001/default;ssl=true;sslTrustStore=`find /opt/spark/conf/keystore/*.truststore |head -n 1`;trustStorePassword=`cat /opt/spark/conf/keystore/pub_truststore_pass`"

# NOTE: This script prompts for a password, then stores in a local temp file.  Since
#       the password is a user's AD password, it doesn't seem worth the risk of
#       having it stored locally where a root user can see it.  Need a better option
#       if users will use beeline frequently.

#echo -n "Enter password for user `whoami`: "
#read -s HS2PASS
#echo ""
#
#TEMP_FILENAME="/tmp/beeline-"`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
#
#touch $TEMP_FILENAME
#chmod 600 $TEMP_FILENAME
#
#trap file_cleanup INT
#
#function file_cleanup()
#{
#  echo "Cleaning up..."
#  if [ -f $TEMP_FILENAME ]; then
#    rm $TEMP_FILENAME
#  fi
#}
#
#echo -n "$HS2PASS" > $TEMP_FILENAME
#
## TODO: For debugging
#echo "/opt/spark/bin/beeline -u \"jdbc:hive2://`hostname --fqdn`:10001/default;ssl=true;sslTrustStore=`find /opt/hive/conf/keystore/*.truststore |head -n 1`;trustStorePassword=`cat /opt/hive/conf/keystore/pub_truststore_pass`\""
#
#/opt/spark/bin/beeline -u "jdbc:hive2://`hostname --fqdn`:10001/default;ssl=true;sslTrustStore=`find /opt/hive/conf/keystore/*.truststore |head -n 1`;trustStorePassword=`cat /opt/hive/conf/keystore/pub_truststore_pass`" -n `whoami` -w "$TEMP_FILENAME"
#
#file_cleanup
