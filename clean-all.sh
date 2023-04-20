#!/usr/bin/env bash

set -e

docker-compose down
docker system prune --force --volumes
echo y | docker system prune --all --force
