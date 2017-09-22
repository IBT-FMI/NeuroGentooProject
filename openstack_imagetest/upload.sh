#!/bin/bash

if [ "$#" -ne 2 ]
then
	echo "OS_USER=<user> OS_PW=<password> OS_TENANT=>tenant> $0 <filename> <imagename>"
	exit 1
fi

glance --os-username "$OS_USER" \
  --os-password "$OS_PW" \
  --os-tenant-name "$OS_TENANT" \
  --os-auth-url https://cloud.s3it.uzh.ch:5000/v2.0 \
  --os-image-api-version 2 \
  image-create \
  --disk-format raw \
  --container-format bare \
  --file $1 \
  --name $2
