#!/bin/bash

source ~/.topology
source hosts

CWD=`pwd`
if [ $# -eq 1 ]
then
  SITE=$1
else
  echo "Usage: $0 <site> "
  exit 0
fi
echo "SITE = $SITE"

for s in $SITES
do
  if [ $SITE = $s ]
  then
    CLIENTS_NAME="${s}_CLIENTS"
    printf -v CLIENT_HOSTS "$CLIENTS_NAME"
    #echo "$s clients: ${!CLIENT_HOSTS}"
  
    echo "Killing traffic clients for site: $s"
    for h in ${!CLIENT_HOSTS}
    do
      ssh ${!h} "killall ndn-traffic"
    done
  fi
  #echo "Done with site: $s"
done


