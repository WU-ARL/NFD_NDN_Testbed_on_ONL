#!/bin/bash

source ~/.topology
source hosts

CWD=`pwd`

for s in $SITES
do
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  echo "Killing traffic clients for site: $s"
  for h in ${!CLIENT_HOSTS}
  do
    ssh ${!h} "killall ndn-traffic"
  done
  #echo "Done with site: $s"
done



for s in $SITES
do
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  echo "Killing traffic servers for site: $s"
  for h in ${!CLIENT_HOSTS}
  do
    ssh ${!h} "killall ndn-traffic-server"
  done
  #echo "Done with site: $s"
done



