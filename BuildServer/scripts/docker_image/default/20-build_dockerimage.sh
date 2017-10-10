#!/bin/bash

NAME="$DOCKER_TAG"
pushd "${ROOT}/../"
docker build -t "$NAME" .
echo "$NAME" >> "${ROOT}"../registry/docker_images
echo "$NAME" > "${ROOT}"../registry/latest_docker_image
popd
