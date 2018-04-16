#!/bin/bash

cp -R data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring domain network configuration routine until next boot."
else
  "${cw_ROOT}"/etc/handlers/domain-networking/initialize
fi
