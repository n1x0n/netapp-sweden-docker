#!/bin/bash

set -o verbose

PASSWORD=changeme
USER_AND_DB=wordpress01

# Set the number of clones to create
# Going above 10 eats up all the memory in our
# demo environment.
NUM_CLONES=$1
if [[ -z $NUM_CLONES ]]
then
    NUM_CLONES=10
fi

# We need to create the volume on all nodes in the swarm.
NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' )


# Loop that creates all volumes
COUNTER=1
while [[ ! $COUNTER -gt $NUM_CLONES ]]
do
    # Cloning volume for this service.
    docker volume create -d ontap-nas -o snapshotDir=false -o snapshotPolicy=default -o from=percona_orig --name percona_clone_${COUNTER}
    for NODE in $NODES
    do
        ssh ${NODE} docker volume create -d ontap-nas --name percona_clone_${COUNTER}
    done


    # Creating the service
    PORT=$(( 3306 + $COUNTER ))
    docker service create \
        --name percona_clone_${COUNTER} \
        --mount src=percona_clone_${COUNTER},dst=/var/lib/mysql \
        -p ${PORT}:3306 \
        percona:latest

    COUNTER=$(( $COUNTER + 1 ))
done

set +o verbose

echo "
All databases have the employees sample database loaded, username is netapp and password is changeme.
"

