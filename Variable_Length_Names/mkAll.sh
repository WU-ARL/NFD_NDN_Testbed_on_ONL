#!/bin/bash

if [ $# -eq 5 ]
then
  COUNT=$1
  PROTO=$2
  INTERVAL=$3
  NUM_SEGMENTS=$4
  SEGMENT_LEN=$5
else
  echo "Usage: $0 <count> <proto> <interval> <num name segments> <segment length>"
  exit 0
fi

pushd rtr
echo "mkRtrs.sh"
./mkRtrs.sh $COUNT $PROTO $NUM_SEGMENTS $SEGMENT_LEN
popd

pushd client
echo "mkClients.sh"
./mkClients.sh $COUNT $PROTO $INTERVAL $NUM_SEGMENTS $SEGMENT_LEN
popd

pushd server
echo "mkServers.sh"
./mkServers.sh $COUNT $PROTO $NUM_SEGMENTS $SEGMENT_LEN
popd 
