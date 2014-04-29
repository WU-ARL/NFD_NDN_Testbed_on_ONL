#!/bin/bash

source ~/.topology
source hosts 

PROTO="udp4"
if [ $# -eq 1 ]
then
  PROTO="$1"
fi

CWD=`pwd`

echo "./configServers.sh"
./configServers.sh ${PROTO}
#./configClients.sh ${PROTO}
echo "./configRtrs.sh"
./configRtrs.sh 
