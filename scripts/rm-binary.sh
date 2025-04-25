#!/usr/bin/env sh

set -f

## Cycle in package list each one element
for package in "$@"; do
  ## Check directory on binary files exists
  for directory in /usr/sbin /usr/bin /sbin /bin; do
    find "${directory}/" ! -type d -wholename "${directory}/${package}" \
      | while read -r binary; do
        [ -n "${binary}" ] || continue
        [ -e "${binary}" ] || continue
        ## Remove divert into custom directory
        dpkg -S "${binary}" >/dev/null 2>&1 || continue
        rm-divert.sh "${binary}"
      done
  done

  ## Finally cycle again and remove unused binary
  for directory in /usr/sbin /usr/bin /sbin /bin; do
    find "${directory}/" ! -type d -wholename "${directory}/${package}" \
      | while read -r binary; do
        [ -n "${binary}" ] || continue
        [ -e "${binary}" ] || continue
        rm -fv "${binary}"
      done
  done
done
