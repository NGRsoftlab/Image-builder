#!/usr/bin/env bash
## GNU bash, версия 5.2.15(1)-release (x86_64-pc-linux-gnu)

## DESCRIPTION
##   This script can create images based on Astra Linux (Debian-like system).
##   To run you need to have docker.io and debootstrap. The following system
##   versions are supported: 1.7.2, 1.7.3, 1.7.4, 1.7.5, 1.7.6, 1.7.7, 1.7.x (latest updated version),
##   1.8.1, 1.8.x (latest updated version)

## EXAMPLE USAGE
##   Help ./build-astra-image.sh -h
##   Build specific image
##   ./build-astra-image.sh -t 1.7.2 \
##                          -c 1.7_x86-64 \
##                          -r https://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.2/repository \
##                          -i my-astra-image-name

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
##   exit code 33
##     Bash not found
##   exit code 5
##     Help text was shown
##   exit code 127
##     Utility not found; you must install it because this script depends on it
##   exit code 128
##     Unsupported distribution version
##   exit code 129
##     Unknown platform arch

## Check bash interpreter is installed
if [ -z "${BASH_VERSION:-}" ]; then
  echo "[timestamp: $(date +%F' '%T)] [level: ERROR] [file: $(basename "${0}")] bash is required to interpret this script"
  exit 33
fi

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
# shellcheck disable=SC2317  # Don't warn about unreachable commands in this file
logger_time() { date +%F' '%T; }

## Definite color variables
logger_tty_reset="$(tty_escape 0)"
logger_tty_red="$(tty_mkbold 31)"
logger_tty_green="$(tty_mkbold 32)"
logger_tty_yellow="$(tty_mkbold 33)"
logger_tty_blue="$(tty_mkbold 34)"

#############################################
## Log the given message at the given level.
#############################################
# Log template for all received.
# All logs are written to stdout with a timestamp.
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
# Check programs on exists
# ARGUMENTS:
#   $@, packages list (array)
# OUTPUTS:
#   Write to stdout if error and exit with 127 code
#############################################
__package_exists() {
  local PKG_LIST PKG_MISSING
  PKG_LIST=("$@")
  PKG_MISSING=false

  for required_pkg in "${PKG_LIST[@]}"; do
    if ! dpkg -l "${required_pkg}" >/dev/null 2>/dev/null; then
      logger_warning_message "please install package - ${required_pkg}"
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
  ## When terminated by Ctrl-C
  logger_warning_message "recived EXIT signal"

  ## Change directory
  logger_info_message "back to ${HOME}"
  pushd "${HOME}" >/dev/null || true

  ## Debootstrap leaves mounted /proc and /sys folders in chroot
  logger_info_message "unmount existings folders"
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
  [[ "${PLATFORM}" == "arm64" && ! ("$(uname -m)" == *arm* || "$(uname -m)" == *aarch64*) ]]
}

#############################################
# Rootfs exec
# ARGUMENTS:
#   $@, command list (array)
# OUTPUTS:
#   Write to stdout
#############################################
__rootfs_chroot() {
  ## Get path to "chroot" in our current PATH
  local CHROOT_PATH
  CHROOT_PATH="$(type -P chroot)"

  ## "chroot" doesn't set PATH, so we need to set it explicitly to something our new debootstrap chroot can use appropriately!
  ## Set PATH and chroot away!
  PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' "${CHROOT_PATH}" "${ROOTFS_DIR}" "$@"
}

#############################################
# Set source list depending on operating system
# OUTPUTS:
#   Write to stdout, if error - exit with 128 code
#############################################
__set_source_list() {
  ## Set source list
  case "${TAG}" in
    1.8.x | 1.8.1)
      echo "deb ${REPO_URL}-extended/ 1.8_x86-64 main contrib non-free non-free-firmware" >>"${ROOTFS_DIR}/etc/apt/sources.list"
      ;;
    1.7.x | 1.7.7 | 1.7.6 | 1.7.5 | 1.7.4 | 1.7.3 | 1.7.2)
      echo "deb ${REPO_URL}-base/ 1.7_x86-64 main contrib non-free" >>"${ROOTFS_DIR}/etc/apt/sources.list"
      echo "deb ${REPO_URL}-extended/ 1.7_x86-64 main contrib non-free" >>"${ROOTFS_DIR}/etc/apt/sources.list"
      echo "deb ${REPO_URL}-update/ 1.7_x86-64 main contrib non-free" >>"${ROOTFS_DIR}/etc/apt/sources.list"
      ;;
    *)
      logger_error_message "unsupported OS"
      exit 128
      ;;
  esac

  logger_info_message "check source list:"
  logger_info_message "$(cat "${ROOTFS_DIR}/etc/apt/sources.list")"
}

#############################################
# Add tweaks for compare image w/ small size
# OUTPUTS:
#   Write to stdout
#############################################
__docker_tweaks() {
  local APT_GET_CLEAN

  logger_info_message "applying docker-specific tweaks"
  ## These are copied from the docker contrib/mkimage/debootstrap script.
  ## Modifications:
  ##  - remove `strings` check for applying the --force-unsafe-io tweak.
  ##     This was sometimes wrongly detected as not applying, and we aren't
  ##     interested in building versions that this guard would apply to,
  ##     so simply apply the tweak unconditionally

  ## Prevent init scripts from running during install/update
  echo >&2 "+ echo exit 101 > '${ROOTFS_DIR}/usr/sbin/policy-rc.d'"
  cat >"${ROOTFS_DIR}/usr/sbin/policy-rc.d" <<-'EOF'
#!/bin/sh
# For most Docker users, "apt-get install" only happens during "docker build",
# where starting services doesn't work and often fails in humorous ways. This
# prevents those failures by stopping the services from attempting to start.
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
  echo >&2 "+ echo force-unsafe-io > '${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker-apt-speedup'"
  cat >"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/docker-apt-speedup" <<-'EOF'
# For most Docker users, package installs happen during "docker build", which
# doesn't survive power loss and gets restarted clean afterwards anyhow, so
# this minor tweak gives us a nice speedup (much nicer on spinning disks,
# obviously).
force-unsafe-io
EOF

  if [[ -d "${ROOTFS_DIR}/etc/apt/apt.conf.d" ]]; then
    ## _keep_ us lean by effectively running "apt-get clean" after every install
    APT_GET_CLEAN='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
    echo >&2 "+ cat > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-clean'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-clean" <<-EOF
# Since for most Docker users, package installs happen in "docker build" steps,
# they essentially become individual layers due to the way Docker handles
# layering, especially using CoW filesystems.  What this means for us is that
# the caches that APT keeps end up just wasting space in those layers, making
# our layers unnecessarily large (especially since we'll normally never use
# these caches again and will instead just "docker build" again and make a brand
# new image).
# Ideally, these would just be invoking "apt-get clean", but in our testing,
# that ended up being cyclic and we got stuck on APT's lock, so we get this fun
# creation that's essentially just "apt-get clean".
DPkg::Post-Invoke { ${APT_GET_CLEAN} };
APT::Update::Post-Invoke { ${APT_GET_CLEAN} };
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
# Note that we do realize this isn't the ideal way to do this, and are always
# open to better suggestions (https://github.com/docker/docker/issues).
EOF

    # remove apt-cache translations for fast "apt-get update"
    echo >&2 "+ echo Acquire::Languages 'none' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-no-languages'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-no-languages" <<-'EOF'
# In Docker, we don't often need the "Translations" files, so we're just wasting
# time and space by downloading them, and this inhibits that.  For users that do
# need them, it's a simple matter to delete this file and "apt-get update".
Acquire::Languages "none";
EOF

    echo >&2 "+ echo Acquire::GzipIndexes 'true' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-gzip-indexes'"
    cat >"${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-gzip-indexes" <<-'EOF'
# Since Docker users using "RUN apt-get update && apt-get install -y ..." in
# their Dockerfiles don't go delete the lists files afterwards, we want them to
# be as small as possible on-disk, so we explicitly request "gz" versions and
# tell Apt to keep them gzipped on-disk.
# For comparison, an "apt-get update" layer without this on a pristine
# "debian:wheezy" base image was "29.88 MB", where with this it was only
# "8.273 MB".
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
EOF

    ## Update "autoremove" configuration to be aggressive about removing suggests deps that weren't manually installed
    echo >&2 "+ echo Apt::AutoRemove::SuggestsImportant 'false' > '${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-autoremove-suggests'"
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
# packages it added.
# https://aptitude.alioth.debian.org/doc/en/ch02s05s05.html#configApt-AutoRemove-SuggestsImportant
Apt::AutoRemove::SuggestsImportant "false";
EOF

    ## Exclude mess doc files
    echo >&2 "+ path-exclude /usr/share/doc/* > '${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc'"
    cat >"${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc" <<-'EOF'
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
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
  local USR_BIN_MODIFICATION_TIME

  ## Clean /etc/hostname and /etc/resolv.conf as they are based on the current env, so make
  ## the chroot different. Docker doesn't care about them, as it fills them when starting
  ## a container
  echo "" >"${ROOTFS_DIR}/etc/resolv.conf"
  echo "host" >"${ROOTFS_DIR}/etc/hostname"

  ## Capture the most recent date that a package in the image was changed.
  ## We don't care about the particular date, or which package it comes from,
  ## we just need a date that isn't very far in the past

  ## We get multiple errors like:
  ## gzip: stdout: Broken pipe
  ## dpkg-parsechangelog: error: gunzip gave error exit status 1
  ## TODO: Why?
  set +o pipefail
  BUILD_DATE="$(find "${ROOTFS_DIR}/usr/share/doc" -name changelog.Debian.gz -print0 | xargs -0 -n1 -I{} dpkg-parsechangelog -SDate -l'{}' | xargs -l -i date --date="{}" +%s | sort -n | tail -n 1 || echo '')"
  set -o pipefail

  logger_info_message "trimming down"
  for DIR in "${DIRS_TO_TRIM[@]}"; do
    rm -r "${ROOTFS_DIR:?ROOTFS_DIR cannot be empty}/${DIR}"/*
  done

  ## Remove the aux-cache as it isn't reproducible. It doesn't seem to
  ## cause any problems to remove it.
  rm "${ROOTFS_DIR}/var/cache/ldconfig/aux-cache"

  ## Remove /usr/share/doc, but leave copyright files to be sure that we
  ## comply with all licenses.
  ## `mindepth 2` as we only want to remove files within the per-package
  ## directories. Crucially some packages use a symlink to another package
  ## dir (e.g. libgcc1), and we don't want to remove those
  find "${ROOTFS_DIR}/usr/share/doc" -mindepth 2 -not -name copyright -not -type d -delete
  find "${ROOTFS_DIR}/usr/share/doc" -mindepth 1 -type d -empty -delete

  ## Set the mtime on all files to be no older than $BUILD_DATE.
  ## This is required to have the same metadata on files so that the
  ## same tarball is produced. We assume that it is not important
  ## that any file have a newer mtime than this
  [[ -z ${BUILD_DATE} ]] || find "${ROOTFS_DIR}" -depth -newermt "@${BUILD_DATE}" -print0 | xargs -0r touch --no-dereference --date="@${BUILD_DATE}"

  rm -rf "${ROOTFS_DIR}/usr/share/groff/"*
  rm -rf "${ROOTFS_DIR}/usr/share/info/"*
  rm -rf "${ROOTFS_DIR}/usr/share/lintian/"*
  rm -rf "${ROOTFS_DIR}/usr/share/linda/"*
  rm -rf "${ROOTFS_DIR}/var/cache/man/"*
  rm -rf "${ROOTFS_DIR}/usr/share/man/"*

  logger_info_message "total size: $(du -skh "${ROOTFS_DIR}")"
  logger_info_message "package sizes"
  ## These aren't shell variables, this is a template, so override sc thinking these are the wrong type of quotes
  # shellcheck disable=SC2016
  __rootfs_chroot dpkg-query -W -f '${Package} ${Installed-Size}\n'
  logger_info_message "largest dirs:"
  logger_info_message "$(du "${ROOTFS_DIR}" | sort -n | tail -n 20)"
  logger_info_message "built in ${ROOTFS_DIR}"

  if __use_qemu_static; then
    logger_info_message "cleaning up qemu static files from image"
    USR_BIN_MODIFICATION_TIME=$(stat -c %y "${ROOTFS_DIR}"/usr/bin)
    rm -rf "${ROOTFS_DIR}"/usr/bin/qemu-*-static
    touch -d "${USR_BIN_MODIFICATION_TIME}" "${ROOTFS_DIR}"/usr/bin
  fi
}

#############################################
# Import custom image with created manifest, return image id
# RETURN:
#   Image id
#############################################
__import() {
  local LAYERSUM TDIR CONF CONF_SHA MANIFEST ID

  ## Create build directory
  mkdir -p "${BUILD_DIR}"

  ## Archive image
  tar cf "${TARGET}" -C "${ROOTFS_DIR}" .

  LAYERSUM="$(sha256sum "${TARGET}" | awk '{print $1}')"

  TDIR="$(mktemp -d)"

  mkdir -p "${TDIR}/${LAYERSUM}"
  cp "${TARGET}" "${TDIR}/${LAYERSUM}/layer.tar"
  echo -n '1.0' >"${TDIR}/${LAYERSUM}/VERSION"

  CONF="$(echo -n "${CONF_TEMPLATE}" | sed -e "s/%PLATFORM%/${PLATFORM}/g" -e "s/%TIMESTAMP%/${TIMESTAMP}/g" -e "s/%LAYERSUM%/${LAYERSUM}/g" -e "s/%COMPANY_NAME%/${COMPANY_NAME}/g")"
  CONF_SHA="$(echo -n "${CONF}" | sha256sum | awk '{print $1}')"

  echo -n "${CONF}" >"${TDIR}/${CONF_SHA}.json"

  MANIFEST="$(echo -n "${MANIFEST_TEMPLATE}" | sed -e "s/%CONF_SHA%/${CONF_SHA}/g" -e "s/%LAYERSUM%/${LAYERSUM}/g")"

  echo -n "${MANIFEST}" >"${TDIR}/manifest.json"

  tar cf "${TDIR}/import.tar" -C "${TDIR}" "manifest.json" "${CONF_SHA}.json" "${LAYERSUM}"

  ID=$(docker load -i "${TDIR}/import.tar" | awk '{print $4}')

  if [[ "${ID}" != "sha256:${CONF_SHA}" ]]; then
    logger_fail "failed to load ${ID} correctly, expected id to be ${CONF_SHA}, source in ${TDIR}"
  fi

  ## Cleanup temp dir
  rm -rf "${TDIR}"

  ## Publish image id
  echo "${ID}"
}

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
  docker run "${DOCKER_PLATFORM_ARGS[@]}" --rm "${BIND_MOUNTS[@]}" ${EXTRA_ARGS} -e DEBIAN_FRONTEND=noninteractive "${IMAGE}" "$@"
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
  __test_args bash -c "(! cut -d: -f3 < ${PATH_SH} | grep -v 17885 >/dev/null) || (cat ${PATH_SH} && false)"
}

#############################################
# Synthetic tests
# OUTPUTS:
#   Write to stdout
#############################################
_test() {
  local BIND_MOUNTS DOCKER_PLATFORM_ARGS MYSQL_PACKAGE
  MYSQL_PACKAGE='default-mysql-server'
  BIND_MOUNTS=()
  DOCKER_PLATFORM_ARGS=()

  if [[ "${PLATFORM}" == "arm64" ]]; then
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
  if [[ "${PLATFORM}" == "amd64" ]]; then
    # shellcheck disable=SC2016
    __test_args bash -c 'echo "$(uname -m)" && [[ "$(uname -m)" == *x86_64* ]]'
  elif [[ "${PLATFORM}" == "arm64" ]]; then
    # shellcheck disable=SC2016
    __test_args bash -c 'echo "$(uname -m)" && [[ "$(uname -m)" == *arm* || "$(uname -m)" == *aarch64* ]]'
  else
    logger_info_message "unknown platform ${PLATFORM}" >&2
    exit 129
  fi

  ## Run 1st test iter
  __desc "checking that a package can be installed with apt"
  __test_args bash -c 'apt-get update && apt-get -y install less && less --help >/dev/null'

  ## Run 2nd test iter
  __desc "checking that a package can be installed with install_packages and that it removes cache dirs"
  __test_args bash -c 'install_packages less  && less --help >/dev/null && [ ! -e /var/cache/apt/archives ] && [ ! -e /var/lib/apt/lists ]'

  ## Run 3th test iter
  __desc "checking that the debootstrap dir wasn't left in the image"
  __test_args bash -c '[ ! -e /debootstrap ]'

  ## Run 4th test iter
  __desc "check that all base packages are correctly installed, including dependencies"
  ## Ask apt to install all packages that are already installed, has the effect of checking the
  ## dependencies are correctly available
  # shellcheck disable=SC2016
  __test_args bash -c 'apt-get update && (dpkg-query -W -f \${Package} | while read pkg; do apt-get install $pkg; done)'

  ## Run 5th test iter
  __desc "check that install_packages doesn't loop forever on failures"
  ## This won't install and will fail. The key is that the retry loop will stop after a few iterations.
  ## We check that we didn't install the package afterwards, just in case a package gets added with that name.
  ## We wrap the whole thing in a timeout so that it doesn't loop forever. It's not ideal to have a timeout as there may be spurious failures if the network is slow.
  __test_args bash -c 'timeout 360 bash -c "(install_packages thispackagebetternotexist || true) && ! dpkg -l thispackagebetternotexist"'

  ## Run 6th test iter
  ## See https://github.com/bitnami/minideb/issues/17
  __desc "checking that the terminfo is valid when running with -t"
  echo "" | __test_extra_args '-t' bash -c 'install_packages procps && top -d1 -n1 -b'

  ## Run 7th test iter
  ## See https://github.com/bitnami/minideb/issues/16
  __desc "check that we can install - ${MYSQL_PACKAGE}"
  __test_args install_packages "${MYSQL_PACKAGE}"

  ## Run 8th test iter
  __desc "check that all users have a fixed day as the last password change date in /etc/shadow"
  __shadow_check /etc/shadow

  ## Run 9th test iter
  __desc "check that all users have a fixed day as the last password change date in /etc/shadow-"
  __shadow_check /etc/shadow-
}

#############################################
# Help menu
# OUTPUTS:
#   Write to stdout
#############################################
_usage() {
  cat <<EOF

NAME:
        ${PROGRAM} - Create Docker image IMAGE_NAME based on REPOSITORY with CODENAME.

SYNOPSIS:
        ${PROGRAM} {-t TAG} [-d DISTRIBUTION] [-r REPOSITORY] [-p PLATFORM] [-v]

DESCRIPTION:
        Script can create astra docker image v1.7.x and v1.8.x.

ARGUMENTS LIST:
        -h                help menu
        -v                print version
        -d                set debug, to enable pass '-d'
        -t TAG            image tag, such as 1.8.1 and etc.
        -c CODENAME       codename (specified in '/etc/os-release' VERSION_CODENAME variable. For this OS it is: $(awk -F'=' '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release || echo 'unknown codename'))
        -r REPOSITORY     address of the repository
        -i IMAGE_NAME     name of the image being created
        -p PLATFORM       platform (based on dpkg --print-architecture command)

AUTHOR:
        Written by ${COMPANY_NAME}.
EOF
}

##
## MAIN SCRIPT
##

[[ -n ${PROGRAM} ]] || PROGRAM=$(basename "${0}")
[[ -n ${VERSION} ]] || VERSION='v1.0.0'
COMPANY_NAME='NGRSoftlab'
readonly PROGRAM VERSION COMPANY_NAME

set -eu -o pipefail

## Set options
while getopts 't:c:r:p:i:dhv' OPTION; do
  case "${OPTION}" in
    t)
      TAG=${OPTARG}
      ;;
    c)
      CODENAME=${OPTARG}
      ;;
    r)
      REPO_URL=${OPTARG}
      ;;
    p)
      PLATFORM=${OPTARG}
      ;;
    i)
      IMAGE_NAME=${OPTARG}
      ;;
    d)
      DEBUG='ON'
      ;;
    v)
      printf "%s (%s) %s" "${PROGRAM}" "${COMPANY_NAME}" "${VERSION}"
      exit 0
      ;;
    h)
      _usage
      exit 0
      ;;
    ?)
      _usage
      exit 5
      ;;
  esac
done

## Check variable and definite variable
: "${TAG:?Specify distr tag, such as '-t 1.8.0' or '-t 1.7.3' and in the same vein}"
: "${CODENAME:=stable}"
: "${REPO_URL:?Specify repository URL, such as '-r https://download.astralinux.ru/astra/stable/1.7_x86-64/repository' or '-r https://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository' and in the same vein}"
: "${PLATFORM:=$(dpkg --print-architecture)}"
: "${IMAGE_NAME:=astra}"
: "${DEBUG:=OFF}"
: "${DOCKER_SAVE_ACTION:=import}"

IMAGE="${IMAGE_NAME}:${TAG}"
DEBIAN_FRONTEND=noninteractive
export TAG CODENAME PLATFORM REPO_URL IMAGE DEBIAN_FRONTEND DEBUG DOCKER_SAVE_ACTION

## Init entrypoint
main() {
  local TIMESTAMP USR_BIN_MODIFICATION_TIME CONF_TEMPLATE MANIFEST_TEMPLATE BUILD_DIR BUILD_REPO TARGET DIRS_TO_TRIM DEBOOTSTRAP_ARCH_ARGS BUILT_IMAGE_ID

  ## Check user id (must be 0)
  [[ "$(id -u)" -eq 0 ]] || logger_fail "this script must be run by root"

  ## Get OS ID
  OS_ID=$(awk -F'=' '$1=="ID" { print $2 ;}' /etc/os-release)

  ## Check running script on Astra OS
  [[ ${OS_ID,,} == 'astra' ]] || logger_fail "required AstraOS for script, but running on '${OS_ID}'"

  ## Set debug
  case "${DEBUG}" in
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
    [Oo][Ff][Ff])
      logger_info_message "debug disable"
      ;;
  esac

  ## Set vars
  TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  CONF_TEMPLATE='{"architecture":"%PLATFORM%","comment":"from %COMPANY_NAME% with love","config":{"Hostname":"","Domainname":"","User":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":null,"Cmd":["/bin/bash"],"Image":"","Volumes":null,"WorkingDir":"","Entrypoint":null,"OnBuild":null,"Labels":null},"container_config":{"Hostname":"","Domainname":"","User":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":null,"Cmd":null,"Image":"","Volumes":null,"WorkingDir":"","Entrypoint":null,"OnBuild":null,"Labels":null},"created":"%TIMESTAMP%","docker_version":"1.13.0","history":[{"created":"%TIMESTAMP%","comment":"from %COMPANY_NAME% with love"}],"os":"linux","rootfs":{"type":"layers","diff_ids":["sha256:%LAYERSUM%"]}}'
  MANIFEST_TEMPLATE='[{"Config":"%CONF_SHA%.json","RepoTags":null,"Layers":["%LAYERSUM%/layer.tar"]}]'
  BUILD_DIR='build'
  BUILD_REPO="${REPO_URL}-main"
  TARGET="${BUILD_DIR}/${TAG}-${PLATFORM}.tar"
  DIRS_TO_TRIM=(
    "/usr/share/man"
    "/var/cache/apt"
    "/var/lib/apt/lists"
    "/usr/share/locale"
    "/var/log"
    "/usr/share/info"
  )
  DEBOOTSTRAP_ARCH_ARGS=(
    "--variant=minbase"
    "--no-check-gpg"
  )

  case "${TAG}" in
    1.8.x | 1.8.1)
      DEBOOTSTRAP_ARCH_ARGS+=("--components=main,contrib,non-free,non-free-firmware")
      ;;
    1.7.x | 1.7.7 | 1.7.6 | 1.7.5 | 1.7.4 | 1.7.3 | 1.7.2)
      DEBOOTSTRAP_ARCH_ARGS+=("--components=main,contrib,non-free")
      ;;
    *)
      logger_error_message "unsupported OS type"
      exit 128
      ;;
  esac

  ## Check packages on exists
  __package_exists "docker.io" "debootstrap"

  trap __cleanup EXIT

  ## Create temp rootfs dir
  ROOTFS_DIR=$(mktemp -d)
  logger_info_message "building base in ${ROOTFS_DIR}"

  ## Create minimal image
  debootstrap "${DEBOOTSTRAP_ARCH_ARGS[@]}" "${CODENAME}" "${ROOTFS_DIR}" "${BUILD_REPO}"

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
  __set_source_list

  ## Change root on docker image and set settings
  __rootfs_chroot apt-get update
  __rootfs_chroot apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef"
  __rootfs_chroot apt-get autoremove -y
  __rootfs_chroot dpkg -l | tee "${TAG}.manifest"

  ## Reduse image size by switch link on perl
  __rootfs_chroot find "/usr/bin/" -wholename "/usr/bin/perl5*" -exec ln -fsv perl {} ';'

  ## Reduse image size by delete mess on apt dir
  __rootfs_chroot find /var/cache/apt/ ! -type d ! -name 'lock' -delete
  __rootfs_chroot find /var/lib/apt/ ! -type d -wholename '/var/lib/apt/listchanges*' -delete
  __rootfs_chroot find /var/lib/apt/lists/ ! -type d ! -name 'lock' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/apt/*' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/aptitude*' -delete
  __rootfs_chroot find /var/tmp/ ! -type d -ls -delete

  ## Reduse image size by delete mess on dpkg dir
  __rootfs_chroot truncate -s 0 "/var/lib/dpkg/available"
  __rootfs_chroot find "/var/lib/dpkg/" ! -type d -wholename "/var/lib/dpkg/*-old" -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/alternatives.log' -delete
  __rootfs_chroot find /var/log/ ! -type d -wholename '/var/log/dpkg.log' -delete
  __rootfs_chroot find "/var/lib/dpkg/" ! -type d -wholename "/var/lib/dpkg/info/*.symbols" -delete
  __rootfs_chroot find /var/cache/debconf/ ! -type d -wholename '/var/cache/debconf/*-old' -delete

  ## Call tweak to set min docker opt
  __docker_tweaks

  ## Call remove cache and doc options
  __remove_cache

  logger_info_message "total size chroot after actions: $(du -sh "${ROOTFS_DIR}")"

  ## Remove image if exists
  docker rmi "${IMAGE}" 2>/dev/null || true

  ## Set save action
  case "${DOCKER_SAVE_ACTION,,}" in
    import)
      ## Import image
      tar -C "${ROOTFS_DIR}" -c . |
        docker import - "${IMAGE}" \
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
      docker tag "${BUILT_IMAGE_ID}" "${IMAGE}"
      ;;
  esac

  logger_info_message "docker image has been generated: ${IMAGE}"

  ## Run synt test
  _test

  logger_info_message "$(date -ud "@${SECONDS}" "+time elapsed: %H:%M:%S")"

  ## Trigger trap function
  exit 0
}

## Call entrypoint
main
