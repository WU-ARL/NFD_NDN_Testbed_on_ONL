#!/bin/bash

source ../hosts


#SITES="CSU AZ REMAP UCI UCLA UCSD PKU TONGJI"
#
#CSU_RTR="h1x2"
#CSU_CLIENTS="h2x2 h2x3"
#CSU_PREFIX="ndn:/ndn/edu/colostate"
#
#AZ_RTR="h3x2"
#AZ_CLIENTS="h4x2 h4x3"
#AZ_PREFIX="ndn:/ndn/edu/arizona"
#
#REMAP_RTR="h5x2"
#REMAP_CLIENTS="h6x2 h6x3"
#REMAP_PREFIX="ndn:/ndn/edu/ucla/remap"
#
#UCI_RTR="h7x2"
#UCI_CLIENTS="h8x2 h8x3"
#UCI_PREFIX="ndn:/ndn/edu/uci"
#
#UCLA_RTR="h9x2"
#UCLA_CLIENTS="h10x2 h10x3"
#UCLA_PREFIX="ndn:/ndn/edu/ucla"
#
#UCSD_RTR="h11x2"
#UCSD_CLIENTS="h12x2 h12x3"
#UCSD_PREFIX="ndn:/ndn/org/caida"
#
#PKU_RTR="h13x2"
#PKU_CLIENTS="h14x2 h14x3"
#PKU_PREFIX="ndn:/ndn/cn/edu/pku"
#
#TONGJI_RTR="h15x2"
#TONGJI_CLIENTS="h16x2 h16x3"
#TONGJI_PREFIX="ndn:/ndn/cn/edu/tongji"

# Router pairs with links:
# (TONGJI,PKU)
# (TONGJI,UCSD)
# (PKU,UCLA)
# (UCLA,UCSD)
# (UCLA,CSU)
# (UCLA,REMAP)
# (UCLA,UCI)
# (REMAP,UCI)
# (UCI,UCSD)
# (CSU,REMAP)
# (REMAP,AZ)
# (CSU,AZ)
# (UCSD,AZ)

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

  # Configure UCLA Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "UCLA" ]
  then
    # UCLA has links to PKU, UCSD, UCI, REMAP and CSU
    # UCLA to PKU
    h=$PKU_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through PKU UCLA can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 5 
    # AZ_PREFIX: 4
    # UCI_PREFIX: 4
    # UCSD_PREFIX: 3
    # REMAP_PREFIX: 5
    # PKU_PREFIX: 1
    # TONGJI_PREFIX: 2
    PREFIX=$CSU_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCLA to UCSD
    h=$UCSD_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCSD UCLA can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 3 
    # AZ_PREFIX: 2
    # UCI_PREFIX: 2
    # UCSD_PREFIX: 1
    # REMAP_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 2
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCLA to UCI
    h=$UCI_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCI UCLA can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 3
    # AZ_PREFIX: 3
    # UCI_PREFIX: 1
    # UCSD_PREFIX: 2
    # REMAP_PREFIX: 2
    # PKU_PREFIX: 4
    # TONGJI_PREFIX: 3
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCLA to REMAP
    h=$REMAP_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through REMAP UCLA can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2
    # AZ_PREFIX: 2
    # UCI_PREFIX: 2
    # UCSD_PREFIX: 3
    # REMAP_PREFIX: 1
    # PKU_PREFIX: 5
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCLA to CSU
    h=$CSU_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through CSU UCLA can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 1
    # AZ_PREFIX: 2
    # UCI_PREFIX: 4
    # UCSD_PREFIX: 3
    # REMAP_PREFIX: 2
    # PKU_PREFIX: 5
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi
  # Configure UCSD Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "UCSD" ]
  then
    # UCSD has links to TONGJI, UCLA, UCI and AZ
    # UCSD to TONGJI
    h=$TONGJI_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through TONGJI UCSD can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 4 
    # AZ_PREFIX: 5
    # UCI_PREFIX: 4
    # UCLA_PREFIX: 3
    # REMAP_PREFIX: 4
    # PKU_PREFIX: 2
    # TONGJI_PREFIX: 1
    PREFIX=$CSU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCSD to UCLA
    h=$UCLA_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCLA UCSD can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2 
    # AZ_PREFIX: 3
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 1
    # REMAP_PREFIX: 2
    # PKU_PREFIX: 2
    # TONGJI_PREFIX: 3
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCSD to UCI
    h=$UCI_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCI UCSD can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 3
    # AZ_PREFIX: 3
    # UCI_PREFIX: 1
    # UCLA_PREFIX: 2
    # REMAP_PREFIX: 2
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCSD to AZ
    h=$AZ_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through AZ UCSD can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2
    # AZ_PREFIX: 1
    # UCI_PREFIX: 3
    # UCLA_PREFIX: 3
    # REMAP_PREFIX: 2
    # PKU_PREFIX: 4
    # TONGJI_PREFIX: 5
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=5
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi
  # Configure REMAP Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "REMAP" ]
  then
    # REMAP has links to CSU, UCLA, UCI and AZ
    # REMAP to CSU
    h=$CSU_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through CSU REMAP can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 1 
    # AZ_PREFIX: 2
    # UCI_PREFIX: 3
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # REMAP to UCLA
    h=$UCLA_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCLA REMAP can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2 
    # AZ_PREFIX: 3
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 1
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 2
    # TONGJI_PREFIX: 3
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # REMAP to UCI
    h=$UCI_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCI REMAP can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 3
    # AZ_PREFIX: 3
    # UCI_PREFIX: 1
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 3
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # REMAP to AZ
    h=$AZ_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through AZ REMAP can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2
    # AZ_PREFIX: 1
    # UCI_PREFIX: 3
    # UCLA_PREFIX: 3
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 4
    # TONGJI_PREFIX: 3
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$AZ_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

  # Configure AZ Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "AZ" ]
  then
    # AZ has links to CSU, REMAP and UCSD
    # AZ to CSU
    h=$CSU_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through CSU AZ can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 1 
    # REMAP_PREFIX: 2
    # UCI_PREFIX: 3
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # AZ to REMAP
    h=$REMAP_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through REMAP AZ can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 2 
    # REMAP_PREFIX: 1
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # AZ to UCSD
    h=$UCSD_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCSD AZ can get to the following prefixes at the indicated cost (hops)
    # CSU_PREFIX: 3
    # REMAP_PREFIX: 3
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 1
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 2
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

  # Configure CSU Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "CSU" ]
  then
    # CSU has links to UCLA, REMAP and AZ
    # CSU to UCLA
    h=$UCLA_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCLA CSU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 3 
    # REMAP_PREFIX: 2
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 1
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 2
    # TONGJI_PREFIX: 3
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # CSU to REMAP
    h=$REMAP_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through REMAP CSU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 2 
    # REMAP_PREFIX: 1
    # UCI_PREFIX: 2
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # CSU to AZ
    h=$AZ_RTR
    #echo "$s rtr: ${!RTR_HOST}"
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through AZ CSU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 1 
    # REMAP_PREFIX: 2
    # UCI_PREFIX: 3
    # UCLA_PREFIX: 3
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 4
    # TONGJI_PREFIX: 3
    PREFIX=$AZ_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

  # Configure UCI Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "UCI" ]
  then
    # UCI has links to UCLA, REMAP and UCSD
    # UCI to UCLA
    h=$UCLA_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCLA UCI can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 3
    # REMAP_PREFIX: 2
    # CSU_PREFIX: 2
    # UCLA_PREFIX: 1
    # UCSD_PREFIX: 2
    # PKU_PREFIX: 2
    # TONGJI_PREFIX: 3
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCI to REMAP
    h=$REMAP_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through REMAP CSU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 2 
    # REMAP_PREFIX: 1
    # CSU_PREFIX: 2
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 4
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # UCI to UCSD
    h=$UCSD_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCSD UCI can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 2 
    # REMAP_PREFIX: 3
    # CSU_PREFIX: 3
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 1
    # PKU_PREFIX: 3
    # TONGJI_PREFIX: 2
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

  # Configure TONGJI Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "TONGJI" ]
  then
    # TONGJI has links to UCSD and PKU 
    # TONGJI to UCSD
    h=$UCSD_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCSD TONGJI can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 2
    # REMAP_PREFIX: 3
    # CSU_PREFIX: 3
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 1
    # UCI_PREFIX: 2
    # PKU_PREFIX: 3
    PREFIX=$AZ_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # TONGJI to PKU
    h=$PKU_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through PKU TONGJI can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 4 
    # REMAP_PREFIX: 3
    # CSU_PREFIX: 3
    # UCLA_PREFIX: 2
    # UCSD_PREFIX: 3
    # UCI_PREFIX: 3
    # PKU_PREFIX: 1
    PREFIX=$AZ_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$PKU_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

  # Configure PKU Rtr to Rtr Faces and Next Hop FIB entries
  if [ $s = "PKU" ]
  then
    # PKU has links to UCLA and TONGJI 
    # PKU to UCLA
    h=$UCLA_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through UCLA PKU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 3
    # REMAP_PREFIX: 2
    # CSU_PREFIX: 2
    # UCLA_PREFIX: 1
    # UCSD_PREFIX: 2
    # UCI_PREFIX: 2
    # TONGJI_PREFIX: 3
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
    # PKU to TONGJI
    h=$TONGJI_RTR
    echo "nfdc create ${PROTO}://${h}:6363 # FaceID: $FACE_ID" >> $FILENAME
    # Through TONGJI PKU can get to the following prefixes at the indicated cost (hops)
    # AZ_PREFIX: 3 
    # REMAP_PREFIX: 4
    # CSU_PREFIX: 4
    # UCLA_PREFIX: 3
    # UCSD_PREFIX: 2
    # UCI_PREFIX: 3
    # TONGJI_PREFIX: 1
    PREFIX=$AZ_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$REMAP_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$CSU_PREFIX
    COST=4
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCLA_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCSD_PREFIX
    COST=2
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$UCI_PREFIX
    COST=3
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    PREFIX=$TONGJI_PREFIX
    COST=1
    echo "nfdc add-nexthop -c $COST ${PREFIX} $FACE_ID " >> $FILENAME
    FACE_ID=$(($FACE_ID + 9))
  fi

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

