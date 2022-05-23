#!/bin/bash

#ASNUMBER=$(snmpwalk -Os -c Gu@ibaT3l3c0m -v2c $2 .1.3.6.1.2.1.15.3.1.9.$1 | cut -d ":" -f2 | cut -d " " -f2)
ASNAME=$(whois -h whois.cymru.com AS$1 | egrep -v Name)
if [ "$ASNAME" = "NO_NAME" ]; then
   ASNAME=""
fi
if [ "$ASNAME" = "" ]; then
   ASNAME=$(whois $1|grep owner: |cut  -d ":" -f 2|sed -e 's/^[ \t]*//')
fi
if [ "$ASNAME" = "" ]; then
   ASNAME=$(whois $1|grep network:Org-Name: |cut  -d ":" -f 3|sed -e 's/^[ \t]*//')
fi
if [ "$ASNAME" = "" ]; then
   ASNAME=$(whois $1|grep netname: |cut  -d ":" -f 2|sed -e 's/^[ \t]*//')
fi
if [ "$ASNAME" = "" ]; then
   ASNAME=NO_NAME
fi

echo $ASNAME
