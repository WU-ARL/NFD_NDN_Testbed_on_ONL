#!/bin/bash

source ../hosts

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

echo "#!/bin/bash" > ../configRtrs.sh
chmod 755 ../configRtrs.sh
echo "source ~/.topology" >> ../configRtrs.sh
echo "CWD=\`pwd\`" >> ../configRtrs.sh


START_FACE_ID=4
INDEX=0
HOSTINDEX=0
for s in $SITES
do
  FACE_ID=$START_FACE_ID
  CLIENTS_NAME="${s}_CLIENTS"
  printf -v CLIENT_HOSTS "$CLIENTS_NAME"
  #echo "$s clients: ${!CLIENT_HOSTS}"
  INDEX=$(($INDEX+1))

  RTR_NAME="${s}_RTR"
  printf -v RTR_HOST "$RTR_NAME"
  #echo "$s rtr: ${!RTR_HOST}"

  #PREFIX_NAME="${s}_PREFIX"
  #printf -v PREFIX "$PREFIX_NAME"
  ##echo "$s prefix: ${!PREFIX}"

  FILENAME="configRtr_${s}.sh"
  echo "#!/bin/bash" > $FILENAME
  chmod 755 $FILENAME
  #echo "# Server Faces" >> $FILENAME
  #echo "# Client Faces" >> $FILENAME
  for h in ${!CLIENT_HOSTS}
  do
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    FACE_ID=$(($FACE_ID + 2))
  done
  echo " ssh \$${!RTR_HOST}  \"cd \$CWD/rtr ; ./${FILENAME}\"  " >> ../configRtrs.sh

done
FACE_ID=$START_FACE_ID
INDEX=0
#echo "INDEX: $INDEX  COUNT: $COUNT"
while [ $INDEX -lt $COUNT ]
do
  for s in $SITES
  do
    FACE_ID=$START_FACE_ID
    CLIENTS_NAME="${s}_CLIENTS"
    printf -v CLIENT_HOSTS "$CLIENTS_NAME"
    #echo "$s clients: ${!CLIENT_HOSTS}"
  
    RTR_NAME="${s}_RTR"
    printf -v RTR_HOST "$RTR_NAME"
    #echo "$s rtr: ${!RTR_HOST}"
  
    PREFIX_NAME="${s}_PREFIX"
    printf -v PREFIX "$PREFIX_NAME"
    #echo "$s prefix: ${!PREFIX}"
  
    FILENAME="configRtr_${s}.sh"
    for h in ${!CLIENT_HOSTS}
    do
      #echo "INDEX: $INDEX  COUNT: $COUNT FILENAME: $FILENAME"
      if [ $INDEX -lt $COUNT ]
      then
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
        echo "nfdc add-nexthop -c 1 ${!PREFIX}${NAME}${EXT} $FACE_ID " >> $FILENAME
        FACE_ID=$(($FACE_ID + 2))
        INDEX=$(($INDEX+1))
      fi
    done
  done
done
exit

NUM_CLIENT_HOSTS=0
INDEX=0
for s in $CLIENT_HOSTS 
do
 #echo $s
 CLIENT_HOST_LIST[$INDEX]="$s"
 INDEX=$(($INDEX+1))
 NUM_CLIENT_HOSTS=$(($NUM_CLIENT_HOSTS+1))
done

NUM_SERVER_HOSTS=0
INDEX=0
for s in $SERVER_HOSTS 
do
 #echo $s
 SERVER_HOST_LIST[$INDEX]="$s"
 INDEX=$(($INDEX+1))
 NUM_SERVER_HOSTS=$(($NUM_SERVER_HOSTS+1))
done

echo "#!/bin/bash" > ./configRtr.sh
chmod 755 ./configRtr.sh

# We have to figure out what the first one will be... guess for now
START_FACE_ID=4
INDEX=0
HOSTINDEX=0
FACE_ID=$START_FACE_ID
# Add faces for Client Hosts
#echo "NUM_CLIENT_HOSTS = $NUM_CLIENT_HOSTS"
echo "# Client Faces" >> ./configRtr.sh
while [ $HOSTINDEX -lt $NUM_CLIENT_HOSTS ]
do
  # create face
  echo "nfdc create ${PROTO}://${CLIENT_HOST_LIST[$HOSTINDEX]}:6363 # FaceID: $FACE_ID" >> ./configRtr.sh
  HOSTINDEX=$(($HOSTINDEX + 1))
  # Count the Client faces so we can remember where the Server Faces start
  FACE_ID=$(($FACE_ID + 2))
done
echo " " >> ./configRtr.sh

# Record where first server face will be
START_FACE_ID=$FACE_ID
HOSTINDEX=0
# Add faces for Server Hosts
#echo "NUM_SERVER_HOSTS = $NUM_SERVER_HOSTS"
echo "# Server Faces" >> ./configRtr.sh
while [ $HOSTINDEX -lt $NUM_SERVER_HOSTS ]
do
  # create face
  echo "nfdc create ${PROTO}://${SERVER_HOST_LIST[$HOSTINDEX]}:6363 # FaceID: $FACE_ID" >> ./configRtr.sh
  HOSTINDEX=$(($HOSTINDEX + 1))
  # Record FACE ID so we have the last Server Face
  MAX_FACE_ID=$FACE_ID
  FACE_ID=$(($FACE_ID + 2))
done

echo " " >> ./configRtr.sh
echo "# Next Hops" >> ./configRtr.sh

## This creates an array consisting of lower case letters, indexed
## from 0
#A=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
#
## Index through the array
#for (( i=0 ; $((i<=25)) ; $((i++)) ))
#do
#        echo "A[$i] = ${A[$i]} "
#
#done

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

# Add a next hop FIB entry for each NAME we are going to generate
FACE_ID=$START_FACE_ID
while [ $INDEX -lt $COUNT ]
do
  # generate the NAME extension
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
  INDEX=$(($INDEX + 1))
  # add next hop
  #echo "nfdc add-nexthop /example/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/ABCDE/FGHIJ/KLMNO/PQRST/UVWXY/Z/$EXT $FACE_ID 1 " >> ./configRtr.sh
  echo "nfdc add-nexthop -c 1 ${NAME}${EXT} $FACE_ID " >> ./configRtr.sh
  FACE_ID=$(($FACE_ID + 2))
  # if we have reached the last server face, go back to first Server face
  if [ $FACE_ID -gt $MAX_FACE_ID ]
  then
    echo " " >> ./configRtr.sh
    FACE_ID=$START_FACE_ID
  fi
done

