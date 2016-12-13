#!/bin/bash

set -o verbose

# This script will create a new service. To make sure that there are no
# name collissions we will add a timestamp to the name of the service
# and the data volume.

# Some variables
TIMESTAMP=$( date '+%s' )
VOLNAME="percona_new_vol_${TIMESTAMP}"
SRVNAME="percona_new_srv_${TIMESTAMP}"
USER_AND_DB="wordpress01"
PASSWORD="changeme"

docker volume create -d ontap-nas -o size=10g -o snapshotDir=false -o snapshotPolicy=default --name ${VOLNAME}

# We need to create the volume on all nodes in the swarm.
NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' )
for NODE in $NODES
do
    ssh ${NODE} docker volume create -d ontap-nas --name ${VOLNAME}
done

docker service create \
    --name ${SRVNAME} \
    -e "MYSQL_ROOT_PASSWORD=${PASSWORD}" \
    -e "MYSQL_PASSWORD=${PASSWORD}" \
    -e "MYSQL_USER=${USER_AND_DB}" \
    -e "MYSQL_DATABASE=${USER_AND_DB}" \
    --mount src=${VOLNAME},dst=/var/lib/mysql \
    -p 3307:3306 \
    percona:latest

set +o verbose

echo "
To cleanup run:
docker service rm ${SRVNAME}"
for NODE in $NODES
do
    echo "ssh ${NODE} docker volume rm ${VOLNAME}"
done
echo "docker volume rm ${VOLNAME}"

