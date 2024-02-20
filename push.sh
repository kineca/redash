#!/usr/bin/env bash

set -eu

circleci config validate
git add .
git commit -m "fix" || true
git push origin `git rev-parse --abbrev-ref HEAD` -f
