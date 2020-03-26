#!/bin/sh
set -e

pwd

rm -f tmp/pids/*.pid

exec "$@"
