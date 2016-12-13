#!/usr/bin/bash

echo "
This script will find all Percona clone services and remove
them as well as associated volumes.
"

echo "Removing unused containers on this node."
docker rm $(docker ps -a -q)

# We need to delete the volume on all nodes in the swarm.
NODES=$( docker node ls | grep -v '*' | grep -v '^ID' | awk '{ print $2 }' | sort )
for NODE in $NODES
do
	echo "Removing unused containers on node \"$NODE\"."
	ssh $NODE 'docker rm $(docker ps -a -q)'
done



