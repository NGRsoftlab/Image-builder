#!/bin/sh

set -e

vale_config=".vale.ini"
vale_config_tmp_dir="/tmp/vale"
vale_config_tmp="$vale_config_tmp_dir/$vale_config"
vale_package_cache_dir="/tmp/vale/packages"
vale_package_list="/tmp/vale/vale-packages.txt"
# Vale preset.
vale_version=3.11.2
vale_download_url="https://github.com/errata-ai/vale/releases/download/v${vale_version}/vale_${vale_version}_Linux_64-bit.tar.gz"
vale_tmp_bin="/tmp/vale/vale"
vale_bin='vale'
# Version of presets.
vale_alex_version=v0.2.3
vale_google_version=v0.6.3
vale_hugo_version=v0.3.0
vale_joblint_version=v0.4.1
vale_microsoft_version=v0.14.2
vale_proselint_version=v0.3.4
vale_readability_version=v0.1.1
vale_write_good_version=v0.4.1
vale_gciu_version=1.0.7

append_with_comma() {
  if [ -n "$1" ]; then
    echo "$1, $2"
  else
    echo "$2"
  fi
}

is_command() {
  command -v "${1}" >/dev/null
}

# Get Vale configuration data.
styles_path=$(grep '^StylesPath\s*=' "$vale_config" | sed -E 's/^StylesPath\s*=\s*(.*)\s*$/\1/' | sed -E 's/[,[:space:]]+/ /g' | awk -F' ' '{ print $1 }')
styles_path_custom=$(find "${styles_path%/*}" -mindepth 1 -maxdepth 1 -type d)
echo "Found StylesPath at '$styles_path'"

# Check 'styles_path' on exits before start.
if [ -d "$styles_path" ]; then
  echo >&2 "Already created field '$styles_path'"
  echo >&2 "If u wanna reinitialized it, just delete '$styles_path' and launch again"
  exit 0
fi

# Create vale tmp folder and tmp config file.
mkdir -p "$vale_config_tmp_dir"
cp "$vale_config" "$vale_config_tmp"

# Check vale bin on exists.
if ! is_command vale; then
  echo "Cannot find 'vale' try to use temporary init"
  cd "${vale_config_tmp_dir}" || exit 1
  wget -q "${vale_download_url}" -O - | tar xzf -
  vale_bin="${vale_tmp_bin}"
  cd - >/dev/null || exit 1
fi

# Fill file with packages.
cat >"$vale_package_list" <<EOF
https://github.com/errata-ai/alex/releases/download/${vale_alex_version}/alex.zip
https://github.com/errata-ai/Google/releases/download/${vale_google_version}/Google.zip
https://github.com/errata-ai/Hugo/releases/download/${vale_hugo_version}/Hugo.zip
https://github.com/errata-ai/Joblint/releases/download/${vale_joblint_version}/Joblint.zip
https://github.com/errata-ai/Microsoft/releases/download/${vale_microsoft_version}/Microsoft.zip
https://github.com/errata-ai/proselint/releases/download/${vale_proselint_version}/proselint.zip
https://github.com/errata-ai/readability/releases/download/${vale_readability_version}/Readability.zip
https://github.com/errata-ai/write-good/releases/download/${vale_write_good_version}/write-good.zip
https://gitlab.com/gitlab-ci-utils/vale-package-gciu/-/releases/${vale_gciu_version}/downloads/GCIU.zip
EOF

# Download package list.
mkdir -p "$vale_package_cache_dir"
while read -r line; do
  echo "Download package from '$line'"
  wget -q -P "$vale_package_cache_dir" "$line"
done <"$vale_package_list"

mkdir -p "$styles_path"

# Update tmp config StylesPath with absolute path. Otherwise, will create folder
# relate to it's location and vale will fail to find the styles.
sed -i -E "s|^StylesPath = .*|StylesPath = $(realpath "$styles_path")|" "$vale_config_tmp"

# `Packages` may be split over multiple lines, so join any split lines in the tmp config file.
sed -i -e :a -e '/\\$/N; s/\\\n//; ta' "$vale_config_tmp"

# Get packages from config and check cache for each.
vale_packages=$(grep '^Packages\s*=' "$vale_config_tmp" | sed -E 's/^Packages\s*=\s*(.*)\s*$/\1/' | sed -E 's/[,[:space:]]+/ /g')
for package in $vale_packages; do
  is_http=$(echo "$package" | grep -E '^https://.*\.zip' || :)
  # Since is_in_cache checks for the complete URL, checks package version as well.
  is_in_cache=$(grep "$package" "$vale_package_list")
  # If package is not found in cache, then use the original package name.
  package_cache="$package"
  # If package not https://*.zip and zip file found in cache, add to packages.
  if [ -z "$is_http" ] && [ -f "$vale_package_cache_dir/$package.zip" ]; then
    package_cache="$vale_package_cache_dir/$package.zip"
    echo "Found package '$package' in package cache"
  else
    # Get zip file name from package URL.
    http_package=$(echo "$package" | grep -E '^https://.*\.zip' | sed -E 's/^https:\/\/.+\/(.+\.zip)$/\1/')
    # If URL found in cached file list and zip file found in cache, then add to packages.
    if [ -n "$is_in_cache" ] && [ -f "$vale_package_cache_dir/$http_package" ]; then
      package_cache="$vale_package_cache_dir/$http_package"
      echo "Found package '$package' in package cache"
    else
      echo "Package '$package' not found in package cache"
    fi
  fi
  vale_packages_cache=$(append_with_comma "$vale_packages_cache" "$package_cache")
done
# Encode '/' in path for variable expansion in sed.
vale_packages_cache_encoded=$(echo "$vale_packages_cache" | sed -E 's/\//\\\//g')
# Replace packages in config with packages from cache, where found.
sed -i -E "s/^Packages\s*=.*$/Packages = $vale_packages_cache_encoded/" "$vale_config_tmp"

# Install vale packages from tmp config file. Vale constructs the folder based
# on package hierarchy, so need to actually run `vale sync`.
echo "Installing Vale packages"
eval "$vale_bin" --config="$vale_config_tmp" sync

# Upgrade with custom settings
if [ -n "$styles_path_custom" ]; then
  for i in $styles_path_custom; do
    cp -R "${i}"/* "$styles_path"
  done
fi

# Remove temporary files
rm -rf "${vale_config_tmp_dir:?}"
