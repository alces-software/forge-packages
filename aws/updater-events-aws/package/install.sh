#!/bin/bash

set -e

cp -R data/* "${cw_ROOT}"

chmod 0700 "${cw_ROOT}"/libexec/share/apply-updates

if [ ! -f "${cw_ROOT}/etc/config.yml" ]; then
  echo "${cw_ROOT}/etc/config.yml not found, but is required for updater-events-aws to function. Postponing configuration until reboot."
else
  "${cw_ROOT}"/etc/handlers/00-updater/initialize >> /var/log/clusterware/updater.log
fi
