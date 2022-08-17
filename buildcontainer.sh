#!/bin/bash -x

POSTGRES_VERSION=`./rundb.sh --version | awk '{print $NF}'`

DOCKER_BUILDKIT=1 docker build -t ghcr.io/gyeeta/postgresdb:latest -t ghcr.io/gyeeta/postgresdb:"$POSTGRES_VERSION" -f ./Dockerfile .

