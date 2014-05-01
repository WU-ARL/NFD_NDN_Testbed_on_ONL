#!/bin/bash

if [ $# -eq 6 ]
then
  COUNT=$1
  PROTO=$2
  INTERVAL=$3
  NUM_SEGMENTS=$4
  SEGMENT_LEN=$5
  AT_SITE=$6
else
  echo "Usage: $0 <count> <proto> <interval> <num name segments> <segment length> <traffic_focus_site>"
  exit 0
fi

source ../hosts

NUMHOSTS=0
INDEX=0
PP_INDEX=0
P_INDEX=0

#PREFIXES=""
for s in $SITES
do
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  #if [ $s = "$AT_SITE" ]
  #then
    PREFIX_NAME="${s}_PREFIX"
    printf -v PREFIX "$PREFIX_NAME"
    #echo "$s prefix: ${!PREFIX}"
    #PREFIXES="$PREFIXES ${!PREFIX}"
  #fi

  for h in ${!CLIENT_HOSTS}
  do
   #echo $h
   if [ $s = "$AT_SITE" ]
   then
     PREFIX_PCT[$PP_INDEX]=1
     P_INDEX=$(($P_INDEX+1))
     HOST_LIST[$INDEX]="SKIP"
   else
     PREFIX_PCT[$PP_INDEX]=0
     HOST_LIST[$INDEX]="$h"
   fi
   PREFIX_LIST[$PP_INDEX]="${!PREFIX}"
   PP_INDEX=$(($PP_INDEX+1))
   INDEX=$(($INDEX+1))
   NUMHOSTS=$(($NUMHOSTS+1))
  done
done
NUM_PREFIXES_USED=$P_INDEX
NUM_PREFIXES_DEFINED=$INDEX

CWD=`pwd`
echo "#!/bin/bash" > ../runTrafficClients.sh
chmod 755 ../runTrafficClients.sh
echo "source ~/.topology" >> ../runTrafficClients.sh
echo "CWD=\`pwd\`" >> ../runTrafficClients.sh
echo "INTERVAL=$INTERVAL"   >> ../runTrafficClients.sh
echo "if [ \$# -eq 1 ]"      >> ../runTrafficClients.sh
echo "then"                 >> ../runTrafficClients.sh
echo "  INTERVAL=\$1"        >> ../runTrafficClients.sh
echo "fi"                   >> ../runTrafficClients.sh


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

#echo "NAME: $NAME"
#exit 0
INDEX=0
HOSTINDEX=0
PCT=$((100/$NUM_PREFIXES_USED))
#echo "PCT=$PCT"

while [ $INDEX -ne $COUNT ]
do
#echo "INDEX=$INDEX COUNT=$COUNT"
  if [ $INDEX -lt 10 ]
  then
    C_EXT="00${INDEX}"
  else if [ $INDEX -lt 100 ]
    then
      C_EXT="0${INDEX}"
    else
      C_EXT="${INDEX}"
    fi
  fi
  FILENAME="NDN_Traffic_Client_${C_EXT}"
  echo "" > $FILENAME
  P=0
  while [ $P -lt $NUM_PREFIXES_DEFINED ]
  do
    if [ $P -lt 10 ]
    then
      S_EXT="00${P}"
    else if [ $P -lt 100 ]
      then
        S_EXT="0${P}"
      else
        S_EXT="${P}"
      fi
    fi
    if [ ${PREFIX_PCT[$P]} -eq 0 ]
    then
      echo "" >> $FILENAME
      echo "#TrafficPercentage=0" >>  $FILENAME
      echo "#Name=${PREFIX_LIST[$P]}${NAME}${S_EXT}" >> $FILENAME
      echo "#MustBeFresh=1" >> $FILENAME
      echo "#NameAppendSequenceNumber=1" >> $FILENAME
      echo "" >> $FILENAME
    else
      echo "" >> $FILENAME
      echo "TrafficPercentage=$PCT" >>  $FILENAME
      echo "Name=${PREFIX_LIST[$P]}${NAME}${S_EXT}" >> $FILENAME
      echo "MustBeFresh=1" >> $FILENAME
      echo "NameAppendSequenceNumber=1" >> $FILENAME
      echo "" >> $FILENAME
    fi
    P=$(($P+1))
  done
  #for p in $PREFIXES
  #do
  #  echo "TrafficPercentage=$PCT" >>  $FILENAME
  #  #echo "Name=/example/$EXT" >> $FILENAME
  #  echo "Name=${p}${NAME}${EXT}" >> $FILENAME
  #  echo "MustBeFresh=1" >> $FILENAME
  #  echo "NameAppendSequenceNumber=1" >> $FILENAME
  #done
  if [ ${HOST_LIST[$HOSTINDEX]} != "SKIP" ]
  then
   echo " ssh \$${HOST_LIST[$HOSTINDEX]} \"cd \$CWD/client ; ndn-traffic -i \$INTERVAL $FILENAME >& client_$C_EXT.log &\"  " >> ../runTrafficClients.sh
  fi
  #echo "TrafficPercentage=100" >  $FILENAME
  ##echo "Name=/example/$EXT" >> $FILENAME
  #echo "Name=${PREFIX_LIST[$HOSTINDEX]}${NAME}${EXT}" >> $FILENAME
  #echo "MustBeFresh=1" >> $FILENAME
  #echo "NameAppendSequenceNumber=1" >> $FILENAME
  #echo " ssh \$${HOST_LIST[$HOSTINDEX]} \"cd \$CWD/client ; ndn-traffic -i \$INTERVAL $FILENAME >& client_$EXT.log &\"  " >> ../runTrafficClients.sh

  HOSTINDEX=$(($HOSTINDEX + 1))
  if [ $HOSTINDEX -ge $NUMHOSTS ]
  then 
    HOSTINDEX=0
  fi
  INDEX=$(($INDEX + 1))

done

#TrafficPercentage=100
#Name=/example/A
#MustBeFresh=1
#NameAppendSequenceNumber=1

