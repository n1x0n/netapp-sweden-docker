#!/bin/bash

set -o verbose

docker service create \
    --name wordpress \
    --replicas 1 \
    -e WORDPRESS_DB_HOST=swarm.sto-demo.europe.netapp.com \
    -e WORDPRESS_DB_USER=wordpress01 \
    -e WORDPRESS_DB_NAME=wordpress01 \
    -e 'WORDPRESS_DB_PASSWORD=netapp13!' \
    --mount src=wordpress01,dst=/var/www/html \
    -p 80:80 \
    wordpress:latest
