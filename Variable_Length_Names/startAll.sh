#!/bin/bash

CWD=`pwd`

source ~/.topology
source hosts

for s in $SITES
do
  echo "Starting nfd for site: $s"
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  for h in ${!CLIENT_HOSTS}
  do
    #echo "ssh to ${!h}"
    ssh ${!h} "cd $CWD ; ./start_nfd.sh" 
  done

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  h="${!RTR_HOST}"
  #echo "ssh ${!h} \"cd $CWD ; ./start_nfd.sh\" "
  ssh ${!h} "cd $CWD ; ./start_nfd.sh" 

  #echo "Done with site: $s"
done

for s in $SITES
do
  echo "Starting nrd for site: $s"
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  for h in ${!CLIENT_HOSTS}
  do
    #echo "ssh to ${!h}"
    ssh ${!h} "cd $CWD ; ./start_nrd.sh" 
  done

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  h="${!RTR_HOST}"
  ssh ${!h} "cd $CWD ; ./start_nrd.sh" 

done


