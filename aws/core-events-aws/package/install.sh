#!/bin/bash

set -e

cp -R data/* "${cw_ROOT}"

chmod 0700 "${cw_ROOT}"/libexec/share/clusterware-key-manager
chmod 0700 "${cw_ROOT}"/libexec/share/nologin-control
mkdir -p "${cw_ROOT}"/var/lib/event-periodic/scripts

if [ ! -f "${cw_ROOT}/etc/config.yml" ]; then
  # This is probably because we're making an image and we won't provide userdata until it boots properly
  echo "${cw_ROOT}/etc/config.yml not found, but is required for core-events-aws to function. Postponing configuration until reboot."
else
  "${cw_ROOT}"/etc/handlers/00-clusterable/preconfigure >> /var/log/clusterware/clusterable.log
  "${cw_ROOT}"/etc/handlers/00-clusterable/initialize >> /var/log/clusterware/clusterable.log
  "${cw_ROOT}"/etc/handlers/00-clusterable/start >> /var/log/clusterware/clusterable.log
  "${cw_ROOT}"/etc/handlers/00-clusterable/node-started >> /var/log/clusterware/clusterable.log
fi
