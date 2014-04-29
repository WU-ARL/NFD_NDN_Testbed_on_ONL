#!/bin/bash

source ~/.topology
source hosts

CWD=`pwd`

echo "Kill Traffic"
./killTraffic.sh

for s in $SITES
do
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  echo "Killing nfd for site: $s"
  for h in ${!CLIENT_HOSTS}
  do
    ssh ${!h} "killall nrd"
    ssh ${!h} "killall nfd"
  done

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  h="${!RTR_HOST}"
  ssh ${!h} "killall nrd"
  ssh ${!h} "killall nfd"

  #echo "Done with site: $s"
done



