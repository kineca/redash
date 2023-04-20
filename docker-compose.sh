#!/usr/bin/env bash

set -eu

docker compose -f compose.yml $@
