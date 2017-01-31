#!/bin/bash

set -o verbose

docker service rm neo4j

~/netapp-sweden-docker/bin/remove_stale_containers.sh

NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' )

docker volume rm neo4j_01_data neo4j_01_logs
# Removing old volumes
for NODE in $NODES
do
    ssh ${NODE} docker volume rm neo4j_01_data neo4j_01_logs
done

docker volume create -d ontap-nas -o size=10g -o snapshotDir=false -o snapshotPolicy=default --name neo4j_01_data
docker volume create -d ontap-nas -o size=10g -o snapshotDir=false -o snapshotPolicy=default --name neo4j_01_logs
for NODE in $NODES
do
    ssh ${NODE} docker volume create -d ontap-nas -o size=10g -o snapshotDir=false -o snapshotPolicy=default --name neo4j_01_data
    ssh ${NODE} docker volume create -d ontap-nas -o size=10g -o snapshotDir=false -o snapshotPolicy=default --name neo4j_01_logs
done

docker service create \
    --name neo4j \
    --mount src=neo4j_01_data,dst=/data \
    --mount src=neo4j_01_logs,dst=/logs \
    -p 7474:7474 \
    -p 7687:7687\
    neo4j:3.1

