#!/bin/bash

set -o verbose

docker service create \
    --name percona \
    -e 'MYSQL_ROOT_PASSWORD=netapp13!' \
    -e 'MYSQL_PASSWORD=netapp13!' \
    -e 'MYSQL_USER=wordpress01' \
    -e 'MYSQL_DATABASE=wordpress01' \
    --mount src=percona01,dst=/var/lib/mysql \
    -p 3306:3306 \
    percona:latest
