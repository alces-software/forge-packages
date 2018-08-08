#!/bin/bash

cp -R data/* "${cw_ROOT}"

rm -f "${cw_ROOT}"/etc/storage/.gitkeep
mkdir -p "${cw_ROOT}"/opt/clusterware-storage

# Tries to download the tarball from the cache server
if [ -n "$FL_CONFIG_CACHE_URL" ]; then
  url="${FL_CONFIG_CACHE_URL}/git/clusterware-storage.tar.gz"
  pushd /tmp >/dev/null
    wget $url 2>/dev/null
  popd >/dev/null
fi

echo "Setting up storage base repository"
if [ -d "${cw_ROOT}/var/lib/storage/repos" ]; then
    echo 'Detected existing repository.'
else
  echo 'Initializing repository:'
  if [ -f /tmp/clusterware-storage.tar.gz ]; then
    mkdir -p "${cw_ROOT}"/var/lib/storage/repos/base
    tar -C "${cw_ROOT}"/var/lib/storage/repos/base -xzf /tmp/clusterware-storage.tar.gz
  else
    require files
    files_load_config --optional serviceware
    export cw_STORAGE_rev cw_STORAGE_track
    "${cw_ROOT}/bin/alces" storage update
  fi
fi
