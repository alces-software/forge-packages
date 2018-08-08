#!/bin/bash

cp -R data/* "${cw_ROOT}"

mkdir -p "${cw_ROOT}"/opt/clusterware-sessions

# Tries to download the tarball from the cache server
if [ -n "$FL_CONFIG_CACHE_URL" ]; then
  url="${FL_CONFIG_CACHE_URL}/git/clusterware-sessions.tar.gz"
  pushd /tmp >/dev/null
    wget $url 2>/dev/null
  popd >/dev/null
fi

echo "Setting up session base repository"
if [ -d "${cw_ROOT}/var/lib/sessions/repos" ]; then
  echo 'Detected existing repository.'
else
  echo 'Initializing repository:'
  if [ -f /tmp/clusterware-sessions.tar.gz ]; then
    mkdir -p "${cw_ROOT}"/var/lib/sessions/repos/base
    tar -C "${cw_ROOT}"/var/lib/sessions/repos/base -xzf /tmp/clusterware-sessions.tar.gz
  else
    require files
    files_load_config --optional serviceware
    export cw_SESSION_rev cw_SESSION_track
    "${cw_ROOT}/bin/alces" session update
    "${cw_ROOT}/bin/alces" session enable default
  fi
fi
