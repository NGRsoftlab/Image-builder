#!/usr/bin/env bash
## GNU bash, версия 5.2.15(1)-release (x86_64-pc-linux-gnu)

## DESCRIPTION
##   This script can create images based on Astra Linux (Debian-like system)
##   To run you need to have docker.io and debootstrap. The following system
##   versions are supported: 1.7.2, 1.7.3, 1.7.4, 1.7.5, 1.7.6, 1.7.7, 1.7.x (latest updated version),
##   1.8.2, 1.8.1, 1.8.x (latest updated version)

## EXAMPLE USAGE
##   Help
##      ./build-astra-image.sh -h
##   Build specific image
##     ./build-astra-image.sh -t 1.7.2 \
##                            -c 1.7_x86-64 \
##                            -r https://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.2/repository \
##                            -i my-astra-image-name

## ISSUES & SOLUTIONS
##    If image error like `contains vulnerabilities`` - disable built-in vulnerability scanning (not recommended)
##    Execute `systemctl edit docker`
##
##    Past into:
## [Service]
## Environment="DOCKER_OPTS=--astra-sec-level 6"
##
##   Execute `systemctl restart docker`
##
##   Or using a configuration file
##
##   Execute `mkdir -p /etc/docker`
##
##   Edit `/etc/docker/daemon.json`
##
##   Paste below data
## {
## "debug" : true,
## "astra-sec-level" : 6
## }
##   Execute `systemctl restart docker`

## EXIT CODES
##   33:
##     Bash not found
##   5:
##     Help text was shown
##   127:
##     Utility not found; you must install it because this script depends on it
##   128:
##     Unsupported distribution version
##   129:
##     Unknown platform arch

## Check bash interpreter is installed
if [ -z "${BASH_VERSION:-}" ]; then
  echo "[timestamp: $(date +%F' '%T)] [level: ERROR] [file: $(basename "${0}")] 'bash' is required to interpret this script"
  exit 33
fi

set -Eeo pipefail

## Check base variables before start
[[ -n ${PROGRAM} ]] || PROGRAM=$(basename "${0}")
[[ -n ${VERSION} ]] || VERSION="v$(<VERSION)"

## Define include device for tar options
[[ -n ${SCF_INCLUDE_DEV} ]] || SCF_INCLUDE_DEV=0

set -u

## Make variables unchanged
COMPANY_NAME='NGRSoftlab'
SCF_SYNTETIC_TEST_ENABLE=0
BASEDIR="$(dirname "${0}")"
SCRIPT_PATH="$(cd "${BASEDIR}" && pwd)"
readonly PROGRAM VERSION COMPANY_NAME SCRIPT_PATH BASEDIR

##
## FUNCTIONS
##

#############################################
# Style format
# ARGUMENTS:
#   $1, it is receive style format (int)
# OUTPUTS:
#   Return to ANSI style with format \033[FORMAT;COLORm
#############################################
tty_escape() { printf "\033[%sm" "${1}"; }

#############################################
# Bold style colors
# ARGUMENTS:
#   $1, it is receive color (int)
# OUTPUTS:
#   Return to ANSI color with format \033[BOLD;COLORm
#############################################
tty_mkbold() { tty_escape "1;${1}"; }

#############################################
# Date format
# OUTPUTS:
#   Return to dynamic actual date format YYYY-MM-DD HH:MM:SS
#############################################
logger_time() { date +%F' '%T; }

## Definite color variables
logger_tty_reset="$(tty_escape 0)"
logger_tty_red="$(tty_mkbold 31)"
logger_tty_green="$(tty_mkbold 32)"
logger_tty_yellow="$(tty_mkbold 33)"
logger_tty_blue="$(tty_mkbold 34)"

## Define tab character
logger_tty_tab() { printf "\t"; }

#############################################
## Log the given message at the given level
#############################################
# Log template for all received
# All logs are written to stdout with a timestamp
# ARGUMENTS:
#   $1, the level with specific color style
# OUTPUTS:
#   Write to stdout
#############################################
logger_template() {
  local TIMESTAMP LEVELNAME COLOR TABS
  TIMESTAMP=$(logger_time)
  LEVELNAME="${1}"

  ## Prepare actions
  case "${LEVELNAME}" in
    "INFO")
      COLOR="${logger_tty_green}"
      TABS=0
      ;;
    "WARNING")
      COLOR="${logger_tty_yellow}"
      TABS=0
      ;;
    "ERROR")
      COLOR="${logger_tty_red}"
      TABS=0
      ;;
    *)
      echo "[timestamp: $(date +%F' '%T)] [level: ERROR] undefined log name"
      exit 1
      ;;
  esac

  ## Translation to the left side of the received log name argument
  shift 1

  ## STDOUT
  printf "[timestamp ${logger_tty_blue}${TIMESTAMP}${logger_tty_reset}] [levelname ${COLOR}${LEVELNAME}${logger_tty_reset}] %${TABS}s %s\n" "$*"
}

#############################################
# Log the given message at level, INFO
# ARGUMENTS:
#   $*, the info text to be printed
# OUTPUTS:
#   Write to stdout
#############################################
logger_info_message() {
  local MESSAGE="$*"
  logger_template "INFO" "${MESSAGE}"
}

#############################################
# Log the given message at level, WARNING
# ARGUMENTS:
#   $*, the warning text to be printed
# OUTPUTS:
#   Write to stdout
#############################################
logger_warning_message() {
  local MESSAGE="$*"
  logger_template "WARNING" "${MESSAGE}"
}

#############################################
# Log the given message at level, ERROR
# ARGUMENTS:
#   $*, the error text to be printed
# OUTPUTS:
#   Write to stdout
#############################################
logger_error_message() {
  local MESSAGE="$*"
  logger_template "ERROR" "${MESSAGE}"
}

#############################################
# Log the given message at level, ERROR
# ARGUMENTS:
#   $*, the fail text to be printed
# OUTPUTS:
#   Write to stdout and exit with status 1
#############################################
logger_fail() {
  logger_error_message "$*"
  exit 1
}

#############################################
# Repeats a separator a specified number of times
# ARGUMENTS:
#   $1, it is separator (string)
#   $2, it is how much repeat ${PATTERN} (integer)
# OUTPUTS:
#   Write to stdout
#############################################
__decor() {
  local PATTERN REPEAT
  PATTERN="${1}"
  REPEAT="${2}"
  seq -s"${PATTERN}" "${REPEAT}" | tr -d '[:digit:]'
}

#############################################
# Validate URL
# RATIONALITY TO USE:
# validate for ALMOST all URL (exclude IDN)
#
# if u want test IDN use this construction:
# `echo "пример.рф" | idn2`
#
# if u used difficult login and password
# with '@' '/' characters, then use this
# construction:
# `http://$(printf '%s' "$login:$password" | jq -sRr @uri)@example.com`
#
# this will ensure that the characters are
# not treated as stop characters by the regular expression mask,
# which could result in an return with a boolean false value
#
# ARGUMENTS:
#   $@, list with url
# RETURN:
#   True(0) or False(1)
#############################################
__validate_url() {
  local url RE DOMAIN DOMAIN_LENGTH

  ## Schema
  RE='^(https?|ftp)://'
  ## Auth
  RE+='([^\/@]+(:([^\/@]|%[0-9a-fA-F]{2})*)?@)?'
  ## Domain
  RE+='(([a-zA-Z0-9-]{1,63}\.)+[a-zA-Z]{2,63}|'
  ## IPv4
  RE+='((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|'
  ## IPv6
  RE+='(\[(([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}|(:[a-fA-F0-9]{1,4}){1,7}|[a-fA-F0-9]{1,4}(:[a-fA-F0-9]{1,4}){1,7}|([a-fA-F0-9]{1,4}:){1,6}:[a-fA-F0-9]{1,4}|([a-fA-F0-9]{1,4}:){1,5}(:[a-fA-F0-9]{1,4}){1,2}|([a-fA-F0-9]{1,4}:){1,4}(:[a-fA-F0-9]{1,4}){1,3}|([a-fA-F0-9]{1,4}:){1,3}(:[a-fA-F0-9]{1,4}){1,4}|([a-fA-F0-9]{1,4}:){1,2}(:[a-fA-F0-9]{1,4}){1,5}|[a-fA-F0-9]{1,4}:((:[a-fA-F0-9]{1,4}){1,6})|:((:[a-fA-F0-9]{1,4}){1,7}|:)|fe80:(:[a-fA-F0-9]{0,4}){0,4}%[0-9a-zA-Z]+|::(ffff(:0{1,4})?:)?((25[0-5]|(2[0-4]|1?[0-9])?[0-9])\.){3}(25[0-5]|(2[0-4]|1?[0-9])?[0-9])|([a-fA-F0-9]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1?[0-9])?[0-9])\.){3}(25[0-5]|(2[0-4]|1?[0-9])?[0-9]))\]))'
  ## Port
  RE+='(:[0-9]{1,5})?'
  ## Path
  RE+='(\/[^[:space:]?#]*)?'
  ## Query
  RE+='(\?[^[:space:]#<>]*)?'
  ## Fragment
  RE+='(\#[^[:space:]]*)?$'

  for url in "$@"; do
    ## Check main catch
    [[ ${url} =~ ${RE} ]] || return 1

    ## Check domain length
    if [[ ${url} =~ ://([^/@:]+) ]]; then
      DOMAIN=${BASH_REMATCH[1]%:*}
      [[ -n ${DOMAIN} ]] || return 1
      DOMAIN_LENGTH=${#DOMAIN}
      if ((DOMAIN_LENGTH > 253)); then
        return 1
      fi
    fi
  done

  return 0
}

#############################################
# Check programs on exists
# ARGUMENTS:
#   $@, packages list (array)
# OUTPUTS:
#   Write to stdout if error and exit with 127 code
#############################################
__package_exists() {
  local PKG_LIST PKG_MISSING required_pkg
  PKG_LIST=("$@")
  PKG_MISSING=false

  for required_pkg in "${PKG_LIST[@]}"; do
    if ! dpkg -l "${required_pkg}" >/dev/null 2>/dev/null; then
      logger_error_message "please install package - '${required_pkg}'"
      PKG_MISSING=true
    fi
  done

  if "${PKG_MISSING}"; then
    exit 127
  fi
}

#############################################
# Trap function
# OUTPUTS:
#   Trap any exit signal and write to stdout
#############################################
# shellcheck disable=SC2317
__cleanup() {
  logger_warning_message "received EXIT signal"

  ## Change directory
  logger_info_message "back to ${HOME}"
  pushd "${HOME}" >/dev/null || true

  ## Debootstrap leaves mounted /proc and /sys folders in chroot
  logger_info_message "unmount existing folders"
  umount "${ROOTFS_DIR}/proc" "${ROOTFS_DIR}/sys" >/dev/null 2>/dev/null || true

  ## Remove temp dir
  logger_info_message "cleanup temp files"
  rm -r "${ROOTFS_DIR}"
}

#############################################
# Check platform type
# RETURN:
#   True(0) or False(1)
#############################################
__use_qemu_static() {
  [[ ${SCF_PLATFORM} == "arm64" && ! ("$(uname -m)" == *arm* || "$(uname -m)" == *aarch64*) ]]
}

#############################################
# Root filesystem exec
# ARGUMENTS:
#   $@, command list (array)
# OUTPUTS:
#   Write to stdout
#############################################
__rootfs_chroot() {
  ## Get path to "chroot" in our current PATH
  local CHROOT_PATH
  CHROOT_PATH="$(type -P chroot)"

  ## "chroot" doesn't set PATH, so we need to set it explicitly to something our new debootstrap chroot can use appropriately
  ## Set PATH, locale, timezone, memory allocation and chroot
  PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=Etc/UTC MALLOC_ARENA_MAX=2 "${CHROOT_PATH}" "${ROOTFS_DIR}" "$@"
}

#############################################
# Calculate timestamp of fresh packages lists
# RETURN:
#   Most recent timestamp that a package in the image was changed
#############################################
__calculate_build_data() {
  local RELEASE_FILES BUILD_DATE_CHANGELOG BUILD_DATE_LISTS

  ## https://til.simonwillison.net/bash/nullglob-in-bash
  trap '$(shopt -p nullglob)' RETURN
  shopt -s nullglob

  BUILD_DATE=''
  RELEASE_FILES=("${ROOTFS_DIR}"/var/lib/apt/lists/*_{In,}Release)
  [[ ${#RELEASE_FILES[@]} -ne 0 ]] || {
    logger_error_message "no 'Release' files found at /var/lib/apt/lists in '${ROOTFS_DIR}'"
    logger_fail "did you forget to populate 'sources.list' or run 'apt-get update' first?"
  }

  ## Capture the most recent date that a package in the image was changed
  ## We don't care about the particular date, or which package it comes from,
  ## we just need a date that isn't very far in the past
  BUILD_DATE_CHANGELOG="$(
    __rootfs_chroot find "/usr/share/doc" -name changelog.Debian.gz -print0 \
      | while IFS= read -r -d '' file; do
        if [[ -s ${file} ]] && gunzip -c "${file}" 2>/dev/null | grep -q "^.* .* .* .*"; then
          gunzip -c "${file}" 2>/dev/null | dpkg-parsechangelog -SDate -l- 2>/dev/null || true
        fi
      done \
      | xargs -I{} date --date="{}" +%s 2>/dev/null \
      | sort -n \
      | tail -n 1 || echo ''
  )"

  ## Capture almost recent date from packages list
  BUILD_DATE_LISTS="$(
    awk -F ': ' '$1 == "Date" { printf "%s%c", $2, 0 }' "${RELEASE_FILES[@]}" \
      | xargs -r0n1 date '+%s' --date \
      | sort -un \
      | tail -1 || echo ''
  )"

  ## Check what we return
  if [[ -z ${BUILD_DATE_CHANGELOG} && -n ${BUILD_DATE_LISTS} ]]; then
    BUILD_DATE="${BUILD_DATE_LISTS}"
  elif [[ -n ${BUILD_DATE_CHANGELOG} && -z ${BUILD_DATE_LISTS} ]]; then
    BUILD_DATE="${BUILD_DATE_CHANGELOG}"
  elif [[ -n ${BUILD_DATE_CHANGELOG} && -n ${BUILD_DATE_LISTS} ]]; then
    [[ ${BUILD_DATE_CHANGELOG} -gt ${BUILD_DATE_LISTS} ]] || BUILD_DATE="${BUILD_DATE_LISTS}"
    [[ ${BUILD_DATE_CHANGELOG} -lt ${BUILD_DATE_LISTS} ]] || BUILD_DATE="${BUILD_DATE_CHANGELOG}"
  fi

  logger_info_message "total date is: '$(date -d @"${BUILD_DATE}")'"
  export BUILD_DATE
}

#############################################
# Add tweaks for compare image w/ small size
# OUTPUTS:
#   Write to stdout
#############################################
__docker_tweaks() {
  local APT_GET_CLEAN EXTRA_SPECIAL_DIRECTORIES OLDIFS FIND_MATCH_INCLUDES SLIM_EXCLUDES SLIM_INCLUDES
  local slim_include slim_exclude DPKG_OUTPUT

  logger_info_message "applying docker-specific tweaks"
  ## These are copied from the docker contrib/mkimage/debootstrap script.
  ## MODIFICATIONS:
  ##  - remove `strings` check for applying the --force-unsafe-io tweak.
  ##     This was sometimes wrongly detected as not applying, and we aren't
  ##     interested in building versions that this guard would apply to,
  ##     so simply apply the tweak unconditionally

  ## Prevent init scripts from running during install/update
  logger_info_message "+ echo exit 101 > '${ROOTFS_DIR}/usr/sbin/policy-rc.d'"
  cat >"${ROOTFS_DIR}/usr/sbin/policy-rc.d" <<-'EOF'
#!/bin/sh
# For most Docker users, "apt-get install" only happens during "docker build",
# where starting services doesn't work and often fails in humorous ways. This
# prevents those failures by stopping the services from attempting to start

exit 101
EOF
  chmod +x "${ROOTFS_DIR}/usr/sbin/policy-rc.d"

  ## Prevent upstart scripts from running during install/update
  (
    set -x
    __rootfs_chroot dpkg-divert --local --rename --add /sbin/initctl
    cp -a "${ROOTFS_DIR}/usr/sbin/policy-rc.d" "${ROOTFS_DIR}/sbin/initctl"
    sed -i 's/^exit.*/exit 0/' "${ROOTFS_DIR}/sbin/initctl"
  )

  ## Shrink a little, since apt makes us cache-fat (wheezy: ~157.5MB vs ~120MB)
  (
    set -x
    __rootfs_chroot apt-get clean
  )

  ## This file is one APT creates to make sure we don't "autoremove" our currently
  ## in-use kernel, which doesn't really apply to debootstraps/Docker images that
  ## don't even have kernels installed
  rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/01autoremove-kernels"

  ## Force dpkg not to call sync() after package extraction (speeding up installs)
  logger_info_message "+ echo force-unsafe-io > '${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker-apt-speedup'"
  cat >"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker-apt-speedup" <<-'EOF'
# For most Docker users, package installs happen during "docker build", which
# doesn't survive power loss and gets restarted clean afterwards anyhow, so
# this minor tweak gives us a nice speedup (much nicer on spinning disks,
# obviously)

force-unsafe-io
EOF

  ## Attach base info about build version
  logger_info_message "attach exclude and include list > '${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker'"
  cat >"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker" <<-'EOF'
# This is the "slim" variant of the Debian base image
# Many files which are normally unnecessary in containers are excluded,
# and this configuration file keeps them that way

EOF

  # https://github.com/debuerreotype/debuerreotype/issues/10
  mapfile -t EXTRA_SPECIAL_DIRECTORIES < <(find "${ROOTFS_DIR}"/usr/share/man -maxdepth 1 -type d -name 'man[0-9]')

  OLDIFS="${IFS}"
  IFS=$'\n'
  set -o noglob
  mapfile -t SLIM_EXCLUDES < <(grep -vE '^#|^$' "${SCRIPT_PATH}/lists/.slimify-excludes" | sort -u)
  mapfile -t SLIM_INCLUDES < <(grep -vE '^#|^$' "${SCRIPT_PATH}/lists/.slimify-includes" | sort -u)
  set +o noglob
  unset IFS
  IFS="${OLDIFS}"

  ## Filling docker configure file
  FIND_MATCH_INCLUDES=()
  for SLIM_INCLUDE in "${SLIM_INCLUDES[@]}"; do
    [[ ${#FIND_MATCH_INCLUDES[@]} -eq 0 ]] || FIND_MATCH_INCLUDES+=('-o')
    FIND_MATCH_INCLUDES+=(-path "${SLIM_INCLUDE}")
  done
  FIND_MATCH_INCLUDES=('(' "${FIND_MATCH_INCLUDES[@]}" ')')

  for slim_exclude in "${SLIM_EXCLUDES[@]}"; do
    {
      echo
      echo "# dpkg -S '${slim_exclude}'"
      if DPKG_OUTPUT="$(__rootfs_chroot dpkg -S "${slim_exclude}" 2>&1)"; then
        echo "${DPKG_OUTPUT}" | sed 's/: .*//g; s/, /\n/g' | sort -u | xargs
      else
        echo "${DPKG_OUTPUT}"
      fi | fold -w 76 -s | sed 's/^/#  /'
      echo "path-exclude ${slim_exclude}"
    } >>"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker"

    if [[ ${slim_exclude} == *'/*' ]]; then
      if [[ -d "${ROOTFS_DIR}/$(dirname "${slim_exclude}")" ]]; then
        ## Use two passes so that we don't fail trying to remove directories from ${SLIM_INCLUDES}
        ## This is our best effort at implementing https://sources.debian.net/src/dpkg/stretch/src/filters.c/#L96-L97 in shell

        ## Step 1 -- delete everything that doesn't match "${SLIM_INCLUDES}" and isn't a directory or a symlink
        __rootfs_chroot \
          find "$(dirname "${slim_exclude}")" \
          -depth -mindepth 1 \
          -not \( -type d -o -type l \) \
          -not "${FIND_MATCH_INCLUDES[@]}" \
          -exec rm -f '{}' ';'

        ## Step 2 -- repeatedly delete any dangling symlinks and empty directories until there aren't any
        ## (might have a dangling symlink in a directory which then makes it empty, or a symlink to an empty directory)
        while [[ "$(
          __rootfs_chroot \
            find "$(dirname "${slim_exclude}")" \
            -depth -mindepth 1 \( -empty -o -xtype l \) \
            -exec rm -rf '{}' ';' -printf '.' \
            | wc -c
        )" -gt 0 ]]; do true; done
      fi
    else
      __rootfs_chroot rm -f "${slim_exclude}"
    fi
  done
  {
    echo
    for slim_include in "${SLIM_INCLUDES[@]}"; do
      echo "path-include ${slim_include}"
    done
  } >>"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker"
  chmod 0644 "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker"

  ## https://github.com/debuerreotype/debuerreotype/issues/10
  if [[ ${#EXTRA_SPECIAL_DIRECTORIES[@]} -gt 0 ]]; then
    mkdir -p "${EXTRA_SPECIAL_DIRECTORIES[@]}"
  fi

  if [[ -d "${ROOTFS_DIR}/etc/apt/apt.conf.d" ]]; then
    ## _keep_ us lean by effectively running "apt-get clean" after every install
    APT_GET_CLEAN='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
    logger_info_message "+ cat > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-clean'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-clean" <<-EOF
# Since for most Docker users, package installs happen in "docker build" steps,
# they essentially become individual layers due to the way Docker handles
# layering, especially using CoW filesystems.  What this means for us is that
# the caches that APT keeps end up just wasting space in those layers, making
# our layers unnecessarily large (especially since we'll normally never use
# these caches again and will instead just "docker build" again and make a brand
# new image)
# Ideally, these would just be invoking "apt-get clean", but in our testing,
# that ended up being cyclic and we got stuck on APT's lock, so we get this fun
# creation that's essentially just "apt-get clean"

DPkg::Post-Invoke { ${APT_GET_CLEAN} };
APT::Update::Post-Invoke { ${APT_GET_CLEAN} };
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";

# Note that we do realize this isn't the ideal way to do this, and are always
# open to better suggestions (https://github.com/docker/docker/issues)
EOF

    ## Remove apt-cache translations for fast "apt-get update"
    logger_info_message "+ echo Acquire::Languages 'none' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-no-languages'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-no-languages" <<-'EOF'
# In Docker, we don't often need the "Translations" files, so we're just wasting
# time and space by downloading them, and this inhibits that.  For users that do
# need them, it's a simple matter to delete this file and "apt-get update"

Acquire::Languages "none";
EOF

    logger_info_message "+ echo Acquire::GzipIndexes 'true' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-gzip-indexes'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-gzip-indexes" <<-'EOF'
# Since Docker users using "RUN apt-get update && apt-get install -y ..." in
# their Dockerfiles don't go delete the lists files afterwards, we want them to
# be as small as possible on-disk, so we explicitly request "gz" versions and
# tell Apt to keep them gzipped on-disk
# For comparison, an "apt-get update" layer without this on a pristine
# "debian:wheezy" base image was "29.88 MB", where with this it was only
# "8.273 MB"

Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
EOF

    ## Update "autoremove" configuration to be aggressive about removing suggests deps that weren't manually installed
    logger_info_message "+ echo Apt::AutoRemove::SuggestsImportant 'false' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-autoremove-suggests'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-autoremove-suggests" <<-'EOF'
# Since Docker users are looking for the smallest possible final images, the
# following emerges as a very common pattern:
#   RUN apt-get update \
#       && apt-get install -y <packages> \
#       && <do some compilation work> \
#       && apt-get purge -y --auto-remove <packages>
# By default, APT will actually _keep_ packages installed via Recommends or
# Depends if another package Suggests them, even and including if the package
# that originally caused them to be installed is removed.  Setting this to
# "false" ensures that APT is appropriately aggressive about removing the
# packages it added
# https://aptitude.alioth.debian.org/doc/en/ch02s05s05.html#configApt-AutoRemove-SuggestsImportant

Apt::AutoRemove::SuggestsImportant "false";
EOF
  fi

  ## Create package install script for additional install, use in image `install_packages nginx`
  cat >"${ROOTFS_DIR}/usr/sbin/install_packages" <<-'EOF'
#!/bin/sh
set -e
set -u
export DEBIAN_FRONTEND=noninteractive
n=0
max=2
until [ $n -gt $max ]; do
    set +e
    (
      apt-get update -qq &&
      apt-get install -y --no-install-recommends "$@"
    )
    CODE=$?
    set -e
    if [ $CODE -eq 0 ]; then
        break
    fi
    if [ $n -eq $max ]; then
        exit $CODE
    fi
    echo "apt failed, retrying"
    n=$(($n + 1))
done
rm -r /var/lib/apt/lists /var/cache/apt/archives
EOF
  chmod 0755 "${ROOTFS_DIR}/usr/sbin/install_packages"

  ## Set the password change date to a fixed date, otherwise it defaults to the current
  ## date, so we get a different image every day. SOURCE_DATE_EPOCH is designed to do this, but
  ## was only implemented recently, so we can't rely on it for all versions we want to build
  ## We also have to copy over the backup at /etc/shadow- so that it doesn't change
  __rootfs_chroot getent passwd | cut -d: -f1 | xargs -n 1 chroot "${ROOTFS_DIR}" chage -d 17885 && cp "${ROOTFS_DIR}/etc/shadow" "${ROOTFS_DIR}/etc/shadow-"
}

#############################################
# Remove cache and mess docs
# OUTPUTS:
#   Write to stdout
#############################################
__remove_cache() {
  local USR_BIN_MODIFICATION_TIME DIRS_TO_TRIM

  ## Clean /etc/hostname and /etc/resolv.conf as they are based on the current env, so make the
  ## chroot different. Docker doesn't care about them, as it fills them when starting a container
  echo "" >"${ROOTFS_DIR}/etc/resolv.conf"
  echo "host" >"${ROOTFS_DIR}/etc/hostname"

  DIRS_TO_TRIM=(
    "/var/cache/apt"
    "/var/lib/apt/lists"
    "/var/log"
  )

  if [[ ${#DIRS_TO_TRIM[@]} -gt 0 ]]; then
    for dir in "${DIRS_TO_TRIM[@]}"; do
      logger_info_message "trimming down '${dir}'"
      # shellcheck disable=SC2115
      rm -r "${ROOTFS_DIR}/${dir}"/*
    done
  fi

  ## https://www.freedesktop.org/software/systemd/man/machine-id.html
  ## For operating system images which are created once and used on multiple machines,
  ## for example for containers or in the cloud, /etc/machine-id should be either missing
  ## or an empty file in the generic file system image
  if [[ -s ${ROOTFS_DIR}/etc/machine-id ]]; then
    echo -n >"${ROOTFS_DIR}/etc/machine-id"
    chmod 0644 "${ROOTFS_DIR}/etc/machine-id"
  fi

  ## Remove the aux-cache as it isn't reproducible
  ## It doesn't seem to cause any problems to remove it
  rm "${ROOTFS_DIR}/var/cache/ldconfig/aux-cache"

  ## Remove /usr/share/doc, but leave copyright files to be sure that we
  ## comply with all licenses
  ## `mindepth 2` as we only want to remove files within the per-package
  ## directories. Crucially some packages use a symlink to another package
  ## dir (e.g. libgcc1), and we don't want to remove those
  find "${ROOTFS_DIR}/usr/share/doc" -mindepth 2 -not -name copyright -not -type d -delete
  find "${ROOTFS_DIR}/usr/share/doc" -mindepth 1 -type d -empty -delete

  ## https://github.com/debuerreotype/debuerreotype/pull/32
  rm -f "${ROOTFS_DIR}/run/mount/utab"
  ## (also remove the directory, but only if it's empty)
  rmdir "${ROOTFS_DIR}/run/mount" 2>/dev/null || :

  ## Set the mtime on all files to be no older than ${BUILD_DATE}
  ## This is required to have the same metadata on files so that the
  ## same tarball is produced. We assume that it is not important
  ## that any file have a newer mtime than this
  [[ -z ${BUILD_DATE} ]] || find "${ROOTFS_DIR}" -depth -newermt "@${BUILD_DATE}" -print0 | xargs -0r touch --no-dereference --date="@${BUILD_DATE}"

  logger_info_message "total size: $(du -skh "${ROOTFS_DIR}")"

  ## These aren't shell variables, this is a template for DPKG packages
  logger_info_message "package sizes:"
  __rootfs_chroot dpkg-query -W -f "\${Package} \${Installed-Size}\n"

  ## Calculate dir sizes
  logger_info_message "largest dirs:"
  logger_info_message "$(du "${ROOTFS_DIR}" | sort -n | tail -n 20)"
  logger_info_message "build into: '${ROOTFS_DIR}' path"

  if __use_qemu_static; then
    logger_info_message "cleaning up qemu static files from image"
    USR_BIN_MODIFICATION_TIME=$(stat -c %y "${ROOTFS_DIR}"/usr/bin)
    rm -rf "${ROOTFS_DIR}"/usr/bin/qemu-*-static
    touch -d "${USR_BIN_MODIFICATION_TIME}" "${ROOTFS_DIR}"/usr/bin
  fi
}

#############################################
# Set 'tar' options list
# RETURN:
#   export 'tar' args variable
#############################################
__set_tar_opts() {
  local APT_VERSION ARCHIVE_NAME EXCLUDES exclude
  ARCHIVE_NAME="${1}"
  TAR_ARGS=()
  APT_VERSION="$(__rootfs_chroot dpkg-query --show --showformat "\${Version}\n" "apt")"
  EXCLUDES=()

  ## if APT is new enough to auto-recreate "partial" directories, let it
  ## (https://salsa.debian.org/apt-team/apt/commit/1cd1c398d18b78f4aa9d882a5de5385f4538e0be)
  if dpkg --compare-versions "${APT_VERSION}" '>=' '0.8~'; then
    EXCLUDES+=(
      './var/cache/apt/**'
      './var/lib/apt/lists/**'
      './var/state/apt/lists/**'
    )
    ## (see also the targeted exclusions in ".tar-exclude" that these are overriding)
  fi

  ## Define base args
  TAR_ARGS=(
    --create
    --file "${ARCHIVE_NAME}"
    --auto-compress
    --directory "${ROOTFS_DIR}"
    --exclude-from "${SCRIPT_PATH}/lists/.tar-exclude"
  )

  ## If define include devices then not exclude then
  [[ ${SCF_INCLUDE_DEV} -eq 1 ]] || EXCLUDES+=('./dev/**')

  for exclude in "${EXCLUDES[@]}"; do
    TAR_ARGS+=(--exclude "${exclude}")
  done

  ## Append side arguments
  TAR_ARGS+=(
    --numeric-owner
    --transform 's,^./,,'
    --sort name
    .
  )

  export TAR_ARGS
}

#############################################
# Import custom image with created manifest, return image id
# RETURN:
#   Image id
#############################################
__import() {
  local LAYERSUM TDIR CONF CONF_SHA MANIFEST ID

  LAYERSUM="$(sha256sum "${TARGET}" | awk '{print $1}')"

  TDIR="$(mktemp -d)"

  mkdir -p "${TDIR}/${LAYERSUM}"
  cp "${TARGET}" "${TDIR}/${LAYERSUM}/layer.tar"
  echo -n '1.0' >"${TDIR}/${LAYERSUM}/VERSION"

  CONF="$(echo -n "${CONF_TEMPLATE}" | sed -e "s/%SCF_PLATFORM%/${SCF_PLATFORM}/g" -e "s/%TIMESTAMP%/${TIMESTAMP}/g" -e "s/%LAYERSUM%/${LAYERSUM}/g" -e "s/%COMPANY_NAME%/${COMPANY_NAME}/g")"
  CONF_SHA="$(echo -n "${CONF}" | sha256sum | awk '{print $1}')"

  echo -n "${CONF}" >"${TDIR}/${CONF_SHA}.json"

  MANIFEST="$(echo -n "${MANIFEST_TEMPLATE}" | sed -e "s/%CONF_SHA%/${CONF_SHA}/g" -e "s/%LAYERSUM%/${LAYERSUM}/g")"

  echo -n "${MANIFEST}" >"${TDIR}/manifest.json"

  tar cf "${TDIR}/import.tar" -C "${TDIR}" "manifest.json" "${CONF_SHA}.json" "${LAYERSUM}"

  ID=$(docker load -i "${TDIR}/import.tar" | awk '{print $4}')

  if [[ ${ID} != "sha256:${CONF_SHA}" ]]; then
    logger_fail "failed to load ${ID} correctly, expected id to be ${CONF_SHA}, source in ${TDIR}"
  fi

  ## Cleanup temp dir
  rm -rf "${TDIR}"

  ## Publish image id
  echo "${ID}"
}

##
## TEST FUNCTION
##

#############################################
# Test description show
# ARGUMENTS:
#   $*, test list (array)
# OUTPUTS:
#   Write to stdout
#############################################
__desc() {
  logger_info_message "TEST: $*"
  __decor "=" "200"
}

#############################################
# Test base
# ARGUMENTS:
#   $1, additional argument to docker (string)
#   $@, commands list to to docker image (array)
# OUTPUTS:
#   Write to stdout
#############################################
__test_extra_args() {
  local EXTRA_ARGS="${1}"
  shift
  # shellcheck disable=SC2086
  docker run "${DOCKER_PLATFORM_ARGS[@]}" --rm "${BIND_MOUNTS[@]}" ${EXTRA_ARGS} -e DEBIAN_FRONTEND=noninteractive "${SCF_IMAGE}" "$@"
  logger_info_message "TEST: OK"
  __decor "*" "200"
}

#############################################
# Test args without additional argument to docker
# ARGUMENTS:
#   $@, commands list to to docker image (array)
# OUTPUTS:
#   Write to stdout
#############################################
__test_args() {
  __test_extra_args "" "$@"
}

#############################################
# Check shadow file
# ARGUMENTS:
#   $1, path where placed shadow file (string)
# OUTPUTS:
#   Write to stdout
#############################################
__shadow_check() {
  local PATH_SH="${1}"
  __test_args sh -c "(! cut -d: -f3 < ${PATH_SH} | grep -v 17885 >/dev/null) || (cat ${PATH_SH} && false)"
}

#############################################
# Synthetic tests
# OUTPUTS:
#   Write to stdout
#############################################
_test_apt() {
  local BIND_MOUNTS DOCKER_PLATFORM_ARGS MYSQL_PACKAGE
  MYSQL_PACKAGE='default-mysql-server'
  BIND_MOUNTS=()
  DOCKER_PLATFORM_ARGS=()

  if [[ ${SCF_PLATFORM} == "arm64" ]]; then
    if [[ "$(uname -m)" == *arm* || "$(uname -m)" == *aarch64* ]]; then
      logger_info_message "running in arm host. QEMU is not needed"
    else
      logger_info_message "setting up qemu static"
      for qemu_static_file in /usr/bin/qemu-*-static; do
        BIND_MOUNTS+=(-v="${qemu_static_file}:${qemu_static_file}")
      done
      DOCKER_PLATFORM_ARGS+=(--platform "linux/arm64")
    fi
  fi

  __desc "checking that apt is installed"
  __test_args dpkg -l apt

  __desc "arch matches"
  if [[ ${SCF_PLATFORM} == "amd64" ]]; then
    # shellcheck disable=SC2016
    __test_args sh -c 'echo "$(uname -m)" && echo "$(uname -m)" | grep -qE ".*x86_64.*"'
  elif [[ ${SCF_PLATFORM} == "arm64" ]]; then
    # shellcheck disable=SC2016
    __test_args sh -c 'echo "$(uname -m)" && echo "$(uname -m)" | grep -qE ".*arm.*|.*aarch64.*"'
  else
    logger_error_message "unknown platform ${SCF_PLATFORM}"
    exit 129
  fi

  ## Run 1st test iter
  __desc "checking that a package can be installed with apt"
  __test_args sh -c 'apt-get update && apt-get -y install less && less --help >/dev/null'

  ## Run 2nd test iter
  __desc "checking that a package can be installed with install_packages and that it removes cache dirs"
  __test_args sh -c 'install_packages less  && less --help >/dev/null && [ ! -e /var/cache/apt/archives ] && [ ! -e /var/lib/apt/lists ]'

  ## Run 3th test iter
  __desc "checking that the debootstrap dir wasn't left in the image"
  __test_args sh -c '[ ! -e /debootstrap ]'

  ## Run 4th test iter
  __desc "check that all base packages are correctly installed, including dependencies"
  ## Ask apt to install all packages that are already installed, has the effect of checking the
  ## dependencies are correctly available
  # shellcheck disable=SC2016
  __test_args sh -c 'apt-get update && (dpkg-query -W -f \${Package} | while read pkg; do apt-get install $pkg; done)'

  ## Run 5th test iter
  __desc "check that install_packages doesn't loop forever on failures"
  ## This won't install and will fail. The key is that the retry loop will stop after a few iterations
  ## We check that we didn't install the package afterwards, just in case a package gets added with that name
  ## We wrap the whole thing in a timeout so that it doesn't loop forever. It's not ideal to have a timeout as
  ## there may be spurious failures if the network is slow
  __test_args sh -c 'timeout 360 sh -c "(install_packages thispackagebetternotexist || true) && ! dpkg -l thispackagebetternotexist"'

  ## Run 6th test iter
  ## See https://github.com/bitnami/minideb/issues/17
  __desc "checking that the terminfo is valid when running with -t"
  echo "" | __test_extra_args '-t' sh -c 'install_packages procps && top -d1 -n1 -b'

  ## Run 7th test iter
  ## See https://github.com/bitnami/minideb/issues/16
  __desc "check that we can install - ${MYSQL_PACKAGE}"
  if [[ ${SCF_IMAGE} == *slim* ]]; then
    logger_warning_message "trying with 'slim' exception"
    __test_args install_packages mariadb-server default-mysql-server
  else
    __test_args sh -c "install_packages ${MYSQL_PACKAGE}"
  fi

  ## Run 8th test iter
  __desc "check that all users have a fixed day as the last password change date in /etc/shadow"
  __shadow_check /etc/shadow

  ## Run 9th test iter
  __desc "check that all users have a fixed day as the last password change date in /etc/shadow-"
  __shadow_check /etc/shadow-

  ## Run 10th test iter
  __desc "check create system account"
  __test_args sh -c 'groupadd -r systemuser --gid=999 && useradd -r -g systemuser --uid=999 --home-dir="/home/user" --shell=/bin/sh systemuser'

  ## Run 11th test iter
  __desc "check create user account"
  __test_args sh -c 'groupadd user --gid=1000 && useradd -g user --uid=1000 --home-dir="/home/user" --shell=/bin/sh user'
}

##
## HELP FUNCTION
##

#############################################
# Help menu
# OUTPUTS:
#   Write to stdout
#############################################
_usage() {
  cat <<EOF

NAME:
$(__decor "$(logger_tty_tab)" "2") ${PROGRAM} - Create Docker image IMAGE_NAME based on REPOSITORY with CODENAME.

SYNOPSIS:
$(__decor "$(logger_tty_tab)" "2") ${PROGRAM} {-t TAG NAME} {-r REPOSITORY} [-i IMAGE NAME] [-c CODENAME] [-p PLATFORM] [-v] [-h] [-d] [-s]

DESCRIPTION:
$(__decor "$(logger_tty_tab)" "2") Script can create astra docker image v1.7.x and v1.8.x.

ARGUMENTS LIST:
$(__decor "$(logger_tty_tab)" "2") -h $(__decor "$(logger_tty_tab)" "3") help menu
$(__decor "$(logger_tty_tab)" "2") -v $(__decor "$(logger_tty_tab)" "3") print version
$(__decor "$(logger_tty_tab)" "2") -d $(__decor "$(logger_tty_tab)" "3") set debug, to enable pass '-d'
$(__decor "$(logger_tty_tab)" "2") -s $(__decor "$(logger_tty_tab)" "3") call only synthetic test for image
$(__decor "$(logger_tty_tab)" "2") -t TAG NAME $(__decor "$(logger_tty_tab)" "2") image tag, such as 1.8.1 and etc.
$(__decor "$(logger_tty_tab)" "2") -c CODENAME $(__decor "$(logger_tty_tab)" "2") codename (specified in '/etc/os-release' VERSION_CODENAME variable. For this OS it is: $(awk -F'=' '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release || echo 'unknown codename'))
$(__decor "$(logger_tty_tab)" "2") -r REPOSITORY $(__decor "$(logger_tty_tab)" "2") address of the repository
$(__decor "$(logger_tty_tab)" "2") -i IMAGE NAME $(__decor "$(logger_tty_tab)" "2") name of the image being created
$(__decor "$(logger_tty_tab)" "2") -p PLATFORM $(__decor "$(logger_tty_tab)" "2") platform (based on dpkg --print-architecture command)

AUTHOR:
$(__decor "$(logger_tty_tab)" "2") Written by ${COMPANY_NAME}.
EOF
}

##
## BUILD FUNCTION
##

build() {
  local USR_BIN_MODIFICATION_TIME BUILT_IMAGE_ID
  local BUILD_DIR BUILD_REPO TARGET DEBOOTSTRAP_ARCH_ARGS
  local DEBOOTSTRAP_ADDITIONAL_SOURSE_LIST

  ## Check user id (must be 0)
  [[ "$(id -u)" -eq 0 ]] || logger_fail "this script must be run by root"

  ## Get OS ID
  OS_ID=$(awk -F'=' '$1=="ID" { print $2 ;}' /etc/os-release)

  ## Check running script on Astra OS
  [[ ${OS_ID,,} == 'astra' ]] || logger_fail "required AstraOS for script, but running on '${OS_ID}'"

  ## Set vars
  TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  CONF_TEMPLATE='{"architecture":"%SCF_PLATFORM%","comment":"from %COMPANY_NAME% with love","config":{"Hostname":"","Domainname":"","User":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":null,"Cmd":["/bin/bash"],"Image":"","Volumes":null,"WorkingDir":"","Entrypoint":null,"OnBuild":null,"Labels":null},"container_config":{"Hostname":"","Domainname":"","User":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":null,"Cmd":null,"Image":"","Volumes":null,"WorkingDir":"","Entrypoint":null,"OnBuild":null,"Labels":null},"created":"%TIMESTAMP%","docker_version":"1.13.0","history":[{"created":"%TIMESTAMP%","comment":"from %COMPANY_NAME% with love"}],"os":"linux","rootfs":{"type":"layers","diff_ids":["sha256:%LAYERSUM%"]}}'
  MANIFEST_TEMPLATE='[{"Config":"%CONF_SHA%.json","RepoTags":null,"Layers":["%LAYERSUM%/layer.tar"]}]'
  BUILD_DIR="${SCRIPT_PATH}/build"
  BUILD_REPO="${SCF_REPO_URL}-main"
  TARGET="${BUILD_DIR}/${SCF_TAG_NAME}-${SCF_PLATFORM}.tar"
  DEBOOTSTRAP_ARCH_ARGS=(
    "--variant=minbase"
    "--no-check-gpg"
  )

  ## Create build directory
  [[ -d ${BUILD_DIR} ]] || mkdir -p "${BUILD_DIR}"

  case "${SCF_TAG_NAME}" in
    1.8.x | 1.8.2 | 1.8.1)
      DEBOOTSTRAP_ARCH_ARGS+=("--components=main,contrib,non-free,non-free-firmware")
      mapfile -t DEBOOTSTRAP_ADDITIONAL_SOURSE_LIST <<EOF
deb ${SCF_REPO_URL}-extended/ 1.8_x86-64 main contrib non-free non-free-firmware
EOF
      ;;
    1.7.x | 1.7.7 | 1.7.6 | 1.7.5 | 1.7.4 | 1.7.3 | 1.7.2)
      DEBOOTSTRAP_ARCH_ARGS+=("--components=main,contrib,non-free")
      mapfile -t DEBOOTSTRAP_ADDITIONAL_SOURSE_LIST <<EOF
deb ${SCF_REPO_URL}-base/ 1.7_x86-64 main contrib non-free
deb ${SCF_REPO_URL}-extended/ 1.7_x86-64 main contrib non-free
deb ${SCF_REPO_URL}-update/ 1.7_x86-64 main contrib non-free
EOF
      ;;
    *)
      logger_error_message "unsupported OS type"
      exit 128
      ;;
  esac

  ## Check packages on exists
  __package_exists "docker.io" "debootstrap"

  ## Trigger on any EXIT signal
  trap __cleanup EXIT

  ## Create temp rootfs dir
  ROOTFS_DIR=$(mktemp -d)

  ## Check chroot file system on empty definite
  : "${ROOTFS_DIR:?ROOTFS_DIR cannot be empty}"

  echo
  logger_info_message "building base in '${ROOTFS_DIR}'"

  ## Create minimal image
  debootstrap "${DEBOOTSTRAP_ARCH_ARGS[@]}" "${SCF_CODENAME}" "${ROOTFS_DIR}" "${BUILD_REPO}"

  ## Check qemu static
  if __use_qemu_static; then
    logger_info_message "setting up qemu static in chroot"
    USR_BIN_MODIFICATION_TIME=$(stat -c %y "${ROOTFS_DIR}"/usr/bin)
    if [[ -f "/usr/bin/qemu-aarch64-static" ]]; then
      find /usr/bin/ -type f -name 'qemu-*-static' -exec cp {} "${ROOTFS_DIR}"/usr/bin/. \;
    else
      logger_fail "cannot find aarch64 qemu static. Aborting..."
    fi
    touch -d "${USR_BIN_MODIFICATION_TIME}" "${ROOTFS_DIR}"/usr/bin
  fi

  ## Set source list for distribution
  printf "%s\n" "${DEBOOTSTRAP_ADDITIONAL_SOURSE_LIST[@]}" >>"${ROOTFS_DIR}/etc/apt/sources.list"
  logger_info_message "check source list:"
  while IFS=$'\n' read -r source_list; do
    logger_info_message "${source_list}"
  done <"${ROOTFS_DIR}/etc/apt/sources.list"
  __decor "-" "200"

  ## Update cache in chroot
  __rootfs_chroot apt-get update

  ## Calculate build data
  __calculate_build_data

  ## Upgrade and get manifest
  __rootfs_chroot apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef"
  __rootfs_chroot apt-get autoremove -y
  __rootfs_chroot dpkg -l | tee "${SCF_TAG_NAME}.manifest"

  ## Reduce image size by switch link on perl
  __rootfs_chroot find "/usr/bin/" -wholename "/usr/bin/perl5*" -exec ln -fsv perl {} ';'

  ## Reduce image size by delete mess on apt dir
  __rootfs_chroot find /var/cache/apt/ ! -type d ! -name 'lock' -delete
  __rootfs_chroot find /var/lib/apt/ ! -type d -wholename '/var/lib/apt/listchanges*' -delete
  __rootfs_chroot find /var/lib/apt/lists/ ! -type d ! -name 'lock' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/apt/*' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/aptitude*' -delete
  __rootfs_chroot find /var/tmp/ ! -type d -ls -delete

  ## Reduce image size by delete mess on dpkg dir
  __rootfs_chroot truncate -s 0 "/var/lib/dpkg/available"
  __rootfs_chroot find "/var/lib/dpkg/" ! -type d -wholename "/var/lib/dpkg/*-old" -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/alternatives.log' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/dpkg.log' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/bootstrap.log' -delete
  __rootfs_chroot find "/var/lib/dpkg/" ! -type d -wholename "/var/lib/dpkg/info/*.symbols" -delete
  __rootfs_chroot find /var/cache/debconf/ ! -type d -wholename '/var/cache/debconf/*-old' -delete

  ## Call tweak to set min docker opt
  __docker_tweaks

  ## Call remove cache and doc options
  __remove_cache

  ## Branding
  cp -f docs/issue "${ROOTFS_DIR}/etc/issue"
  echo "Base image container version ${VERSION}" >>"${ROOTFS_DIR}/etc/issue"
  grep -qF 'cat /etc/issue' "${ROOTFS_DIR}/etc/bash.bashrc" || echo 'cat /etc/issue' >>"${ROOTFS_DIR}/etc/bash.bashrc"

  logger_info_message "total size chroot after actions: $(du -sh "${ROOTFS_DIR}")"

  ## Remove image if exists
  docker rmi "${SCF_IMAGE}" 2>/dev/null || true

  ## Set tar options
  __set_tar_opts "${TARGET}"

  ## Archive image
  tar "${TAR_ARGS[@]}"
  touch --no-dereference --date="@${BUILD_DATE}" "${TARGET}"

  ## Set save action
  case "${SCF_DOCKER_SAVE_ACTION,,}" in
    import)
      ## Import image
      docker import "${TARGET}" "${SCF_IMAGE}" \
        --change "ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        --change "ENV TERM xterm-256color" \
        --change "ENV DEBIAN_FRONTEND noninteractive" \
        --change 'CMD ["/bin/bash"]' \
        --change "WORKDIR /" \
        --message "from ${COMPANY_NAME} with love"
      ;;
    load)
      ## Load image
      BUILT_IMAGE_ID=$(__import)
      docker tag "${BUILT_IMAGE_ID}" "${SCF_IMAGE}"
      ;;
  esac

  logger_info_message "docker image has been generated: '${SCF_IMAGE}'"

  ## Run synt test
  _test_apt
}

##
## MAIN FUNCTION
##

main() {
  ## Set options
  while getopts 't:c:r:p:i:dhvs' OPTION; do
    case "${OPTION}" in
      t)
        SCF_TAG_NAME="${OPTARG}"
        ;;
      c)
        SCF_CODENAME="${OPTARG}"
        ;;
      r)
        SCF_REPO_URL="${OPTARG}"
        ;;
      p)
        SCF_PLATFORM="${OPTARG}"
        ;;
      i)
        SCF_IMAGE_NAME="${OPTARG}"
        ;;
      d)
        SCF_DEBUG='ON'
        ;;
      v)
        printf "%s (%s) %s\n" "${PROGRAM}" "${COMPANY_NAME}" "${VERSION}"
        exit 0
        ;;
      h)
        _usage
        exit 0
        ;;
      s)
        SCF_SYNTETIC_TEST_ENABLE=1
        ;;
      ?)
        _usage
        exit 5
        ;;
    esac
  done
  shift $((OPTIND - 1))

  ## Check and definite variable
  : "${SCF_TAG_NAME:?Specify distribution tag, such as '-t 1.8.0' or '-t 1.7.3' and in the same vein}"
  : "${SCF_IMAGE_NAME:=astra}"
  : "${SCF_PLATFORM:=$(dpkg --print-architecture)}"
  : "${SCF_DEBUG:=OFF}"

  SCF_IMAGE="${SCF_IMAGE_NAME}:${SCF_TAG_NAME}"
  DEBIAN_FRONTEND=noninteractive
  export SCF_TAG_NAME SCF_PLATFORM SCF_IMAGE_NAME SCF_DEBUG SCF_IMAGE DEBIAN_FRONTEND

  ## Info before launch
  logger_info_message "Final launch variables:"
  logger_info_message "Tag name: $(__decor "$(logger_tty_tab)" "4")${SCF_TAG_NAME}"
  logger_info_message "Image name: $(__decor "$(logger_tty_tab)" "4")${SCF_IMAGE_NAME}"
  logger_info_message "Image format: $(__decor "$(logger_tty_tab)" "4")${SCF_IMAGE}"
  logger_info_message "Platform architecture: $(logger_tty_tab)${SCF_PLATFORM}"
  logger_info_message "Enable debug: $(__decor "$(logger_tty_tab)" "4")${SCF_DEBUG}"
  __decor "*" "200"

  ## Set debug
  case "${SCF_DEBUG}" in
    [Oo][Nn])
      ## Detailed verbose
      #+ Levels of indirection and time
      PS4='+\011 \t '
      #+ User ID [Effective user ID]: Groups of user is a member
      PS4+='$UID[$EUID]:$GROUPS '
      #+ Shell level and subshell
      PS4+='\011 L$SHLVL:S$BASH_SUBSHELL '
      #+ Source file
      PS4+='${BASH_SOURCE:-$0}'
      #+ Line number
      PS4+='#:${LINENO} '
      #+ Function name
      PS4+='\011 ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
      #+ Executed command
      PS4+='\n# '
      export PS4
      set -x
      ;;
  esac

  ## Call entrypoint
  if [[ ${SCF_SYNTETIC_TEST_ENABLE} -eq 1 ]]; then
    _test_apt
  else
    : "${SCF_CODENAME:=stable}"
    : "${SCF_REPO_URL:?Specify repository URL, such as '-r https://download.astralinux.ru/astra/stable/1.7_x86-64/repository' or '-r https://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository' and in the same vein}"
    : "${SCF_DOCKER_SAVE_ACTION:=import}"
    export SCF_CODENAME SCF_REPO_URL SCF_DOCKER_SAVE_ACTION
    logger_info_message "Codename: $(__decor "$(logger_tty_tab)" "4")${SCF_CODENAME}"
    logger_info_message "Repository URL: $(__decor "$(logger_tty_tab)" "3")${SCF_REPO_URL}"
    logger_info_message "Docker save method: $(__decor "$(logger_tty_tab)" "3")${SCF_DOCKER_SAVE_ACTION}"
    __decor "*" "200"

    ## Check URL valid
    __validate_url "${SCF_REPO_URL}" || logger_fail "'${SCF_REPO_URL}' is not valid URL"

    ## Start build image
    build
  fi

  ## Trigger trap function
  logger_info_message "$(date -ud "@${SECONDS}" "+time elapsed: %H:%M:%S")"
  [[ ${SCF_SYNTETIC_TEST_ENABLE} -eq 1 ]] || exit 0
}

## Call entrypoint
main "$@"
