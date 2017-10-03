#!/bin/bash

NAME="$MACHINE:$(date +%s)"
pushd "${ROOT}/../"
docker build -t "$NAME".
echo "$NAME" >> "${ROOT}"../registry/docker_images
popd
