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
echo

# We need to delete the volume on all nodes in the swarm.
NODES=$( docker node ls | awk '/Active/ { print $(NF-3) }' | sort )

echo "Waiting for services to stop."
for NODE in $NODES
do
	while true
	do
		ssh $NODE docker ps --filter status=running | grep -q percona_clone
		if [[ ! $? = 0 ]]
		then
			echo "  - All services down on $NODE"
			# Cleanup any remaining containers
			COUNTER=0
			EMPTY=0
			while [[ $COUNTER -lt 10 ]]
			do
				ssh $NODE docker ps -a | grep -q percona_clone_
				if [[ $? = 0 ]]
				then
					COUNTER=$(( $COUNTER + 1 ))
				else
					EMPTY=1
					break
				fi
				sleep 1
			done

			if [[ $EMPTY = 0 ]]
			then
				echo "    - Removing old containers on $NODE"
				ssh $NODE docker ps -a | grep percona_clone_ | awk '{ print $1 }' | xargs ssh $NODE docker rm
			fi

			break
		fi

		sleep 1
	done
done

echo
echo "Removing volumes."
docker volume ls | grep -q percona_clone_ 
if [[ $? = 0 ]]
then
	docker volume ls | grep percona_clone_ | awk '{ print $2 }' | xargs docker volume rm
else
	echo "  - No volumes found."
fi




