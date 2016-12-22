#!/usr/bin/bash

set -o verbose

docker run --name registry -p 5000:5000 \
    -e "REGISTRY_STORAGE=s3" \
    -e "REGISTRY_STORAGE_S3_REGION=generic" \
    -e "REGISTRY_STORAGE_S3_REGIONENDPOINT=grid-gateway.sto-demo.europe.netapp.com:8082" \
    -e "REGISTRY_STORAGE_S3_BUCKET=sto-demo-registry" \
    -e "REGISTRY_STORAGE_S3_ACCESSKEY=3MMTIOHN35MB9ECD3SKJ" \
    -e "REGISTRY_STORAGE_S3_SECRETKEY=NI4/0yGw2PSjSCpGHqDuRM6UoSoYfth9o46Tipeg" \
    -e "REGISTRY_STORAGE_S3_SECURE=true" \
    -v registry01:/var/lib/registry \
    n1x0n/registry:0.4
