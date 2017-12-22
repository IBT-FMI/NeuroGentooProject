#!/bin/bash

OS_USER=""
OS_PW=""
OS_TENANT=""
OS_IMGID=""

glance --os-username "$OS_USER" \
  --os-password "$OS_PW" \
  --os-tenant-name "$OS_TENANT" \
  --os-auth-url https://cloud.s3it.uzh.ch:5000/v2.0 \
  --os-image-api-version 2 \
  image-upload "$OS_IMGID" \
  --file "$OPENSTACK_IMAGE"

