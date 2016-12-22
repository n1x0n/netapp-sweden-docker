#!/usr/bin/bash

# This will create a new Docker Registry service that uses
# our local StorageGRID Webscale object store as backend.

# Normally you would never put your secret key in a file like
# this and push it to Github, but our demo environment is
# behind our firewall and all data in that tenant is publicly 
# available Docker images so in this case it is ok.

# The image we use is based on registry:2 and the only change
# is that we added the ca cert from StorageGRID to the
# certificate bundle. In a production environment you would
# have a proper certificate installed in StorageGRID and in
# that case you can use the standard registry:2 image.

set -o verbose

docker service create \
    --name registry \
    -p 5000:5000 \
    -e "REGISTRY_STORAGE=s3" \
    -e "REGISTRY_STORAGE_S3_REGION=generic" \
    -e "REGISTRY_STORAGE_S3_REGIONENDPOINT=grid-gateway.sto-demo.europe.netapp.com:8082" \
    -e "REGISTRY_STORAGE_S3_BUCKET=sto-demo-registry" \
    -e "REGISTRY_STORAGE_S3_ACCESSKEY=3MMTIOHN35MB9ECD3SKJ" \
    -e "REGISTRY_STORAGE_S3_SECRETKEY=NI4/0yGw2PSjSCpGHqDuRM6UoSoYfth9o46Tipeg" \
    -e "REGISTRY_STORAGE_S3_SECURE=true" \
    --mount src=registry01,dst=/var/lib/registry \
    n1x0n/registry:0.4
