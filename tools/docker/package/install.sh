#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Docker configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/configure-docker/configure"
  "${cw_ROOT}/etc/handlers/configure-docker/start"
fi
