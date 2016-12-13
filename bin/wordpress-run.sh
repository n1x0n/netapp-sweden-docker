#!/bin/bash

set -o verbose

docker run  -it --rm \
    --name wordpress \
    -e WORDPRESS_DB_HOST=swarm.sto-demo.europe.netapp.com \
    -e WORDPRESS_DB_USER=wordpress01 \
    -e WORDPRESS_DB_NAME=wordpress01 \
    -e 'WORDPRESS_DB_PASSWORD=netapp13!' \
    -v wordpress01:/var/www/html \
    wordpress:latest 
