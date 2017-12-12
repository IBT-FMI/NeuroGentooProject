#!/bin/bash

TAG="buffepva/repositorg:${DOCKER_BUILDID}"

docker tag "${DOCKER_TAG}" "${TAG}"
docker push "${TAG}"
