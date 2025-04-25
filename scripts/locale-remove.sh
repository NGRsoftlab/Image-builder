#!/usr/bin/env sh

set -ex

## Update locales
dpkg-divert --add --rename --divert /etc/locale.gen.real /etc/locale.gen
printf 'ru_RU.utf8 UTF-8\nen_US.utf8 UTF-8\n' >/etc/locale.gen
rm -f /usr/lib/locale/locale-archive

LOCALE_LIST="${1}"

if [ -n "${LOCALE_LIST}" ]; then
  LOCALE_LIST="${LOCALE_LIST} en_US.UTF8 ru_RU.UTF8"
elif [ -z "${LOCALE_LIST}" ]; then
  LOCALE_LIST='en_US.UTF8 ru_RU.UTF8'
fi

## Sort uniq elements
LOCALE_LIST=$(echo "${LOCALE_LIST}" | awk '{for (i=1;i<=NF;i++) if (!a[$i]++) printf("%s%s",$i,FS)}{printf("\n")}')

## Define locale hardly method
for i in ${LOCALE_LIST}; do
  ## Define char map
  CHARACTER_MAP_FILE="$(echo "${i}" | awk -F'.' '{print $2}')"

  ## Redefine UTF8
  if expr "X${CHARACTER_MAP_FILE}" : 'X[Uu][Tt][Ff]8' >/dev/null; then
    CHARACTER_MAP_FILE="UTF-8"
  fi

  INPUT_FILE="$(echo "${i}" | awk -F'.' '{print $1}')"

  localedef -i "${INPUT_FILE}" -f "${CHARACTER_MAP_FILE}" "/usr/lib/locale/${i}"

  ## Check locale
  locale -a | grep -i "${i}"

  if [ ! -f /usr/lib/locale/locale-archive ] && expr "X${i}" : 'Xen_US\.[Uu][Tt][Ff]*' >/dev/null; then
    ln -s "/usr/lib/locale/${i}" /usr/lib/locale/locale-archive
  fi

  ## Add to generate
  printf '%s\n' "${i} ${CHARACTER_MAP_FILE}" >>/etc/locale.gen
done

## Prune all unused locales
find /usr/share/locale/ -mindepth 1 -maxdepth 1 \
  -name "*" \
  ! -name 'en*' \
  ! -name 'ru*' \
  ! -name 'locale.alias' \
  -exec rm -rf {} \;

find /usr/share/i18n/locales/ -mindepth 1 -maxdepth 1 -type f \
  -name "*" \
  ! -name "translit_*" \
  ! -name "iso14651_t1_common" \
  ! -name "i18n_ctype" \
  ! -name "i18n" \
  ! -name "iso14651_t1" \
  ! -name "en_GB" \
  ! -name "en_US" \
  ! -name "ru_RU" \
  ! -name "C" \
  ! -name "POSIX" \
  -exec rm -rf {} \;

find /usr/share/i18n/charmaps -mindepth 1 -maxdepth 1 -type f \
  -name "*" \
  ! -name "UTF-8.gz" \
  ! -name "ISO-8859-1.gz" \
  -exec rm -rf {} \;

## Disable locales update
apt-mark hold locales
