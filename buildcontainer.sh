#!/bin/bash -x

DOCKER_BUILDKIT=1 docker build -t gyeeta/postgresdb:latest -t ghcr.io/gyeeta/postgresdb:latest -f ./Dockerfile .

