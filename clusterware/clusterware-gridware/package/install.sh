#!/bin/bash

cp -R data/opt/clusterware/* "${cw_ROOT}"

sed -i -e "s,_ROOT_,${cw_ROOT},g" "${cw_ROOT}/etc/profile.d/11-packager.csh" \
  "${cw_ROOT}"/etc/sudoers.d/*
chmod 0400 "${cw_ROOT}"/etc/sudoers.d/*
mkdir -p /var/cache/gridware/{archives,archives/depots,src} /var/log/gridware

sed -e "/^#=Alces Serviceware/i #=Alces Gridware Depots" \
    -i "${cw_ROOT}"/etc/modulerc/modulespath

if ! /usr/bin/getent group gridware >/dev/null; then
  echo "Configuring gridware group"
  /usr/bin/getent group gridware >/dev/null || /usr/sbin/groupadd -g 341 gridware
fi

echo "Updating gridware permissions"
access_targets=(/var/cache/gridware /var/log/gridware "${cw_ROOT}"/etc/modulerc/modulespath)
chmod -R g+rw "${access_targets[@]}"
find "${access_targets[@]}" -type d -exec chmod 2775 {} \;
chgrp -R gridware "${access_targets[@]}"

# Tries to download the tarball from the cache server
if [ -n "$FL_CONFIG_CACHE_URL" ]; then
  main="${FL_CONFIG_CACHE_URL}/git/gridware-packages-main.tar.gz"
  volatile="${FL_CONFIG_CACHE_URL}/git/gridware-packages-volatile.tar.gz"
  depot="${FL_CONFIG_CACHE_URL}/git/gridware-depots.tar.gz"
  pushd /tmp >/dev/null
    wget $main 2>/dev/null
    wget $volatile 2>/dev/null
    wget $depot 2>/dev/null
  popd >/dev/null
fi

echo "Setting up default gridware package repositories"
if [ ! -d "${cw_ROOT}/var/lib/gridware/repos" ]; then
  if [ ! -f "${cw_ROOT}"/var/lib/gridware/repos/main/repo.yml ]; then
    mkdir -p "${cw_ROOT}"/var/lib/gridware/repos/main
    cp data/dist/repos/main/repo.yml "${cw_ROOT}"/var/lib/gridware/repos/main/repo.yml
  fi
  if [ ! -f "${cw_ROOT}"/var/lib/gridware/repos/volatile/repo.yml ]; then
    mkdir -p "${cw_ROOT}"/var/lib/gridware/repos/volatile
    cp data/dist/repos/volatile/repo.yml "${cw_ROOT}"/var/lib/gridware/repos/volatile/repo.yml
  fi

  if [ -f "/tmp/gridware-packages-main.tar.gz" ]; then
    mkdir -p "${cw_ROOT}"/var/lib/gridware/repos/main
    tar -C "${cw_ROOT}"/var/lib/gridware/repos/main -xzf /tmp/gridware-packages-main.tar.gz
    mkdir -p "${cw_ROOT}"/var/lib/gridware/repos/volatile/pkg
    tar -C "${cw_ROOT}"/var/lib/gridware/repos/volatile/pkg -xzf /tmp/gridware-packages-volatile.tar.gz
  else
    cat <<EOF > "${cw_ROOT}"/etc/gridware.yml
:last_update_filename: .last_update
:log_root: /var/log/gridware
:repo_paths:
- ${cw_ROOT}/var/lib/gridware/repos/main
- ${cw_ROOT}/var/lib/gridware/repos/volatile
EOF
    "${cw_ROOT}/bin/alces" gridware update main 2>&1
    "${cw_ROOT}/bin/alces" gridware update volatile 2>&1
    rm -f "${cw_ROOT}"/etc/gridware.yml
  fi

  chmod -R g+rw "${cw_ROOT}"/var/lib/gridware/repos/*
  find "${cw_ROOT}"/var/lib/gridware/repos/* -type d -exec chmod 2775 {} \;
  chgrp -R gridware "${cw_ROOT}"/var/lib/gridware/repos/*
fi

echo "Setting up default gridware depot repository"
if [ ! -d "${cw_ROOT}/var/lib/gridware/depots" ]; then
  if [ ! -f "${cw_ROOT}"/var/lib/gridware/depots/official/repo.yml ]; then
    mkdir -p "${cw_ROOT}"/var/lib/gridware/depots/official
    cp data/dist/depots/official/repo.yml "${cw_ROOT}"/var/lib/gridware/depots/official/repo.yml
  fi

  if [ -f '/tmp/gridware-depots.tar.gz' ]; then
    mkdir -p "${cw_ROOT}"/var/lib/gridware/depots/official/data
    tar -C "${cw_ROOT}"/var/lib/gridware/depots/official/data -xzvf /tmp/gridware-depots.tar.gz
  else
    cat <<EOF > "${cw_ROOT}"/etc/gridware.yml
:last_update_filename: .last_update
:log_root: /var/log/gridware
:depot_repo_paths:
  - ${cw_ROOT}/var/lib/gridware/depots/official
EOF
    "${cw_ROOT}/bin/alces" gridware depot update official 2>&1
    rm -f "${cw_ROOT}"/etc/gridware.yml
  fi

  chmod -R g+rw "${cw_ROOT}"/var/lib/gridware/depots/official/data
  find "${cw_ROOT}"/var/lib/gridware/depots/official/data -type d -exec chmod 2775 {} \;
  chgrp -R gridware "${cw_ROOT}"/var/lib/gridware/depots/official/data
fi

echo "Installing container data files"
if [ ! -d "${cw_ROOT}/var/lib/gridware/docker" ]; then
  cp -R data/docker "${cw_ROOT}"/var/lib/gridware
fi

alces gridware init
alces gridware depot enable local
