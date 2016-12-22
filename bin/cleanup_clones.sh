#!/usr/bin/bash

echo "
This script will find all Percona clone services and remove
them as well as associated volumes.
"

CLONES=$( docker service ls | grep percona_clone_ | awk '{ print $2 }' | sort )

for CLONE in $CLONES
do
	echo "Removing service \"$CLONE\"."
	docker service rm $CLONE
done

echo "Waiting for services to stop."
sleep 10

# We need to delete the volume on all nodes in the swarm.
NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' )

echo "Removing volumes on this node."
docker volume ls | grep percona_clone_ | awk '{ print $2 }' | xargs docker volume rm
for NODE in $NODES
do
	echo "Removing volumes on node \"$NODE\"."
	ssh $NODE "docker volume ls | grep percona_clone_ | awk '{ print \$2 }' | xargs docker volume rm"
done


# NETAPP
