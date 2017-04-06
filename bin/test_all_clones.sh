#!/usr/bin/bash

TESTCMD="${HOME}/sample_data/test_db/sql_test.sh"
CONNECT_STRING="mysql -h swarm -u netapp -pchangeme -P"
cd "$( dirname "$TESTCMD" )"

CLONE=percona_clone_1
PORT=3309

echo "
This script will find all Percona clone services and run
the test suite associated with the MySQL employees sample
database against them.

Because we want to run this in parallel we simply start a
docker container for each test. We want to make sure that
the Percona client and dependencies are installed in the
container where we run the test, so we use the same image
for the tests as we do in the server containers.

Instead of providing database volumes and running the
Percona server as we do in the server containers we just
mount the directory with the test script as a volume and
run the test script from inside these test containers.

Sample command to start a test container:
docker run -d --name "${CLONE}_tester" \\
  -v $HOME/sample_data/test_db:/test_db \\
  percona:5.7.17 \\
  sh -c \"/test_db/sql_test.sh 'mysql -h swarm -u netapp -pchangeme -P $PORT' >/test_db/results/result.txt\"

============================================================
"

CLONES=$( docker service ls | grep percona_clone_ | awk '{ print $2 }' | sort -n )

mkdir -p $HOME/sample_data/test_db/results
rm $HOME/sample_data/test_db/results/* 2>/dev/null

START=$(date +%s.%N)

for CLONE in $CLONES
do
	PORT=$( docker service inspect $CLONE | grep "PublishedPort" | sed 's/,$//' | tail -1 | awk '{ print $NF }' )
	echo "Testing clone \"$CLONE\" on port $PORT."
	docker run -d --name "${CLONE}_tester" -v $HOME/sample_data/test_db:/test_db percona:5.7.17 sh -c "/test_db/sql_test.sh 'mysql -h swarm -u netapp -pchangeme -P $PORT' >/test_db/results/${CLONE}_tester.txt; echo '${CLONE}_tester' >>/test_db/results/complete.txt; chown -R 1000:1000 /test_db/results"
	echo ""
done

SPINNER='-\|/'
i=0
NUMCLONES=$( echo $CLONES | wc -w )
NUMCOMPLETE=0
while sleep .2
do
	COMPLETE=""
	if [[ -f  $HOME/sample_data/test_db/results/complete.txt ]]
	then
		COMPLETE=$(<$HOME/sample_data/test_db/results/complete.txt )
		NUMCOMPLETE=$( echo $COMPLETE | wc -w )
	fi

	printf '\r    '
	printf '.%.0s' $CLONES
	printf " ($NUMCOMPLETE/$NUMCLONES)"
	printf '\r'
        i=$(( (i+1) %4 ))
        printf "(${SPINNER:$i:1}) "

	if [[ ! -z $COMPLETE ]]	
	then
		printf '#%.0s' $COMPLETE
	fi

	if [[ $NUMCLONES -eq $NUMCOMPLETE ]]
	then
		break
	fi
done

END=$(date +%s.%N)

for CLONE in $CLONES
do
	echo; echo
	docker rm "${CLONE}_tester"
	echo "${CLONE}_tester" | sed 's/./=/g'
	echo
	cat $HOME/sample_data/test_db/results/${CLONE}_tester.txt
done

echo
echo "Total time for testing $NUMCLONES clones: $( printf "%.3f" $(echo "$END - $START" | bc) ) seconds"
echo


