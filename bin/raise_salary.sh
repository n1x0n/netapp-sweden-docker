#!/usr/bin/bash

CONNECT_STRING="mysql -v -t -h swarm -u netapp -pchangeme -D employees -P"

echo "
One of our developers has decided to give himself a raise
and makes some adjustments to the database.

Press Enter to continue...  "

read DUMMY

SLEEP=2

CLONES=$( docker service ls | grep percona_clone_ | awk '{ print $2 }' | sort -V | tail -1 )

for CLONE in $CLONES
do
	PORT=$( docker service inspect $CLONE | grep "PublishedPort" | sed 's/,$//' | tail -1 | awk '{ print $NF }' )
	MYSQL="$CONNECT_STRING $PORT"
	echo "Making adjustments to clone \"$CLONE\" on port $PORT."
	sleep $SLEEP

	COMMAND="SELECT * FROM employees WHERE first_name = 'Niclas' AND last_name = 'Plumb';"
	echo; echo "$COMMAND" | $MYSQL 
        echo "  ^^^^^^ -- First find the employee number"
	sleep $SLEEP

	COMMAND="SELECT * FROM salaries WHERE emp_no = '294545';"
	echo; echo "$COMMAND" | $MYSQL | sed 's/\(9999.*\)/\1 <-- Find the current salary/'
	sleep $SLEEP

	COMMAND="UPDATE salaries SET salary = '999999' WHERE emp_no = '294545' AND from_date = '2002-01-09';"
	echo; echo "Update the current salary..." ; echo "$COMMAND" | $MYSQL 
	sleep $SLEEP

	COMMAND="SELECT * FROM salaries WHERE emp_no = '294545';"
	echo; echo "$COMMAND" | $MYSQL | sed 's/\(9999.*\)/\1 <-- New salary stored in the database/'
	sleep $SLEEP
done


