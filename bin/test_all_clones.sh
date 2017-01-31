#!/usr/bin/bash

TESTCMD="${HOME}/sample_data/test_db/sql_test.sh"
CONNECT_STRING="mysql -h swarm -u netapp -pchangeme -P"
cd "$( dirname "$TESTCMD" )"


echo "
This script will find all Percona clone services and run
the test suite associated with the MySQL employees sample
database against them.
"

CLONES=$( docker service ls | grep percona_clone_ | awk '{ print $2 }' | sort )

for CLONE in $CLONES
do
	PORT=$( docker service inspect $CLONE | grep "PublishedPort" | sed 's/,$//' | tail -1 | awk '{ print $NF }' )
	echo "Testing clone \"$CLONE\" on port $PORT."
	$TESTCMD "${CONNECT_STRING}${PORT}"
	echo ""
done


