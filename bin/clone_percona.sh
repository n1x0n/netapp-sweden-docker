#!/usr/bin/bash

# Set the number of clones to create
# Going above 10 eats up all the memory in our
# demo environment.
NUM_CLONES=$1
if [[ -z $NUM_CLONES ]]
then
    NUM_CLONES=10
fi

echo "
Percona is a fork of the popular MySQL database. The
Percona docker image uses a volume for persistent storage
and in this demo we have created that volume using the
NetApp Docker Volume Plugin (nDVP). 

The demo has been prepared by loading the data from the
MySQL employees sample database into the Percona database.

This script uses nDVP to create thin clones of the
database and creates docker services running Percona
against each of these clones.

There is a test suite associated with the MySQL employees
sample database and once the clones are ready you can
run the test suite against the clones using the script
'test_all_clones.sh'.

Sample command to create a clone:
docker volume create -d ontap-nas -o snapshotDir=false \\
  -o snapshotPolicy=default -o from=percona_orig \\
  --name percona_clone_1

Sample command to create the service:
docker service create \\
  --name percona_clone_1 \\
  --mount src=percona_clone_1,dst=/var/lib/mysql \\
  --mount src=percona_clone_logs_1,dst=/var/log/mysql \\
  -p 3307:3306 \\
  percona:5.7.17

============================================================
"

START=$(date +%s.%N)

# We need to create the volume on all nodes in the swarm.
NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' )

# Loop that creates all volumes
echo "Creating $NUM_CLONES clones using nDVP"
i=0
SPINNER='|/-\'

printf "\r(${SPINNER:$i:1}) "
printf '.%.0s' $( eval echo {1..${NUM_CLONES}} )
printf " (0/$NUM_CLONES)"

COUNTER=1
while [[ ! $COUNTER -gt $NUM_CLONES ]]
do
    i=$(( (i+1) %4 ))
    # Cloning volume for this service.
    docker volume create -d ontap-nas -o snapshotDir=false -o snapshotPolicy=default -o from=percona_orig --name percona_clone_${COUNTER} >/dev/null
    docker volume create -d ontap-nas -o snapshotDir=false -o snapshotPolicy=default -o from=percona_logs_orig --name percona_clone_logs_${COUNTER} >/dev/null
    for NODE in $NODES
    do
        ssh ${NODE} docker volume create -d ontap-nas --name percona_clone_${COUNTER} >/dev/null
        ssh ${NODE} docker volume create -d ontap-nas --name percona_clone_logs_${COUNTER} >/dev/null
    done

    # Creating the service
    PORT=$(( 3306 + $COUNTER ))
    docker service create \
        --name percona_clone_${COUNTER} \
        --mount src=percona_clone_${COUNTER},dst=/var/lib/mysql \
        --mount src=percona_clone_logs_${COUNTER},dst=/var/log/mysql \
        -p ${PORT}:3306 \
        percona:5.7.17 >/dev/null

        printf "\r(${SPINNER:$i:1}) "
	printf '.%.0s' $( eval echo {1..${NUM_CLONES}} )
	printf " ($COUNTER/$NUM_CLONES)"
        printf "\r(${SPINNER:$i:1}) "
	printf '#%.0s' $( eval echo {1..${COUNTER}} ) 
    COUNTER=$(( $COUNTER + 1 ))
done

END=$(date +%s.%N)

TIME=$(echo "$END - $START" | bc)

echo
echo
echo "Total time for creating $NUM_CLONES clones: $( printf "%.3f" $TIME ) seconds"
echo


