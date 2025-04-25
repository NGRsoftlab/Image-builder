#!/usr/bin/env sh

set -ef

## Check receiving arg on exists
: "${1:?}"

## Associate program with path
DIVERT_DIR=$(printf '%s' "/run/program/divert/${1}" | tr -s '/')

## Create directory
mkdir -p "${DIVERT_DIR%/*}"

## Remove divert
dpkg-divert --divert "${DIVERT_DIR}" --rename "${1}" 2>/dev/null

## Remove program
rm -f "${DIVERT_DIR}"
