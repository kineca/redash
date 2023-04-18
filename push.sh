#!/usr/bin/env bash

set -eu

git add .
git commit -m "fix" || true
git push origin `git rev-parse --abbrev-ref HEAD` -f
