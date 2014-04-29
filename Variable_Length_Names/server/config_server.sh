#!/bin/bash
source ../hosts

if [ $# -eq 2 ]
then
  PROTO="$1"
  RTR_HOST="$2"
else
  echo "Usage: $0 <protocol> <rtr_host>"
  exit 0
fi


nfdc create ${PROTO}://${RTR_HOST}:6363
nfdc add-nexthop -c 1 / 4 

