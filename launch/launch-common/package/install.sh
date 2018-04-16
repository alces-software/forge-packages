#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Flight Launch configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/launch-account-bucket-setup/configure"
fi
