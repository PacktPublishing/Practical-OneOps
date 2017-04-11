#!/bin/bash
HOST=$1
PORT=$2
URL=$3
USERNAME=$4
PASSWORD=$5
WAITTIME=$6
CRITICAL=$7
EXPECT=$8
REGEX=$9

ec=1

out=`/opt/nagios/libexec/check_http -H $HOST -p $PORT  -a "$USERNAME:$PASSWORD" -u "$URL" -w $WAITTIME  -c $CRITICAL -e "$EXPECT" -r "$REGEX"`

ec=$?


if [ $ec != 0 ]; then
 echo "critical_response=1 fail = 1 |  time=6.00; size=0.00; critical_response=1.00\n"
else
 echo "$out critical_response=0.00;"
fi
exit $?