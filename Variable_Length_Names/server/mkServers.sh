#!/bin/bash

if [ $# -eq 4 ]
then
  COUNT=$1
  PROTO=$2
  NUM_SEGMENTS=$3
  SEGMENT_LEN=$4
else
  echo "Usage: $0 <count> <proto> <num name segments> <segment length>"
  exit 0
fi

source ../hosts

NUMHOSTS=0
INDEX=0
echo "#!/bin/bash" > ../configServers.sh
chmod 755 ../configServers.sh
echo "source ~/.topology" >> ../configServers.sh
echo "CWD=\`pwd\`" >> ../configServers.sh

for s in $SITES
do
  SERVERS_NAME="${s}_CLIENTS"
  printf -v SERVER_HOSTS "$SERVERS_NAME"
  #echo "$s clients: ${!SERVER_HOSTS}"

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  PREFIX_NAME="${s}_PREFIX"
  printf -v PREFIX "$PREFIX_NAME"
  #echo "$s prefix: ${!PREFIX}"


  for h in ${!SERVER_HOSTS}
  do
   #echo $h
   HOST_LIST[$INDEX]="$h"
   PREFIX_LIST[$INDEX]="${!PREFIX}"
   INDEX=$(($INDEX+1))
   NUMHOSTS=$(($NUMHOSTS+1))
   echo " ssh \$$h \"cd \$CWD/server ; ./config_server.sh ${PROTO} ${!RTR_HOST}\" " >> ../configServers.sh
  done
done

echo "#!/bin/bash" > ../runTrafficServers.sh
chmod 755 ../runTrafficServers.sh
echo "source ~/.topology" >> ../runTrafficServers.sh
echo "CWD=\`pwd\`" >> ../runTrafficServers.sh

ALPHA_LIST=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
k=0
i=0
NAME="/"
while [ $i -lt $NUM_SEGMENTS ]
do
  j=0
  while [ $j -lt $SEGMENT_LEN ]
  do
    NAME="$NAME""${ALPHA_LIST[$k]}"
    j=$(($j+1))
    k=$(($k+1))
    if [ $k -ge 26 ]
    then
      k=0
    fi
  done
  i=$(($i+1))
  NAME="$NAME""/"
done

INDEX=0
HOSTINDEX=0
while [ $INDEX -lt $COUNT ]
do
#echo "INDEX=$INDEX COUNT=$COUNT"
  if [ $INDEX -lt 10 ]
  then
    EXT="00${INDEX}"
  else if [ $INDEX -lt 100 ]
    then
      EXT="0${INDEX}"
    else
      EXT="${INDEX}"
    fi
  fi
  FILENAME="NDN_Traffic_Server_$EXT"
  #echo "Name=/example/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/$EXT" > $FILENAME
  echo "Name=${PREFIX_LIST[$HOSTINDEX]}${NAME}${EXT}" > $FILENAME
  echo "ContentType=1" >> $FILENAME
  #echo "ContentBytes=10" >> $FILENAME
  echo "Content=AAAAAAAAAA" >> $FILENAME


  #echo " ssh \$${HOST_LIST[$HOSTINDEX]}  \"cd \$CWD/server ; ndn-traffic-server -q $FILENAME >& server_$EXT.log &\"  " >> ../runTrafficServers.sh
  echo " ssh \$${HOST_LIST[$HOSTINDEX]}  \"cd \$CWD/server ; ndn-traffic-server $FILENAME >& server_$EXT.log &\"  " >> ../runTrafficServers.sh

  INDEX=$(($INDEX + 1))
  HOSTINDEX=$(($HOSTINDEX + 1))
  if [ $HOSTINDEX -ge $NUMHOSTS ]
  then 
    HOSTINDEX=0
  fi

done

#Name=/example/A
#ContentType=1
#ContentBytes=10

