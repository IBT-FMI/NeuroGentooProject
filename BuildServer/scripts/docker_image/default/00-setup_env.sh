#!/bin/bash

DOCKER_TAG="$MACHINE:$(date +%s)"
ensure_dir "${ROOT}/../registry/"
