#!/bin/bash

yum install -y -e0 pciutils

cp -R data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring GPU configuration routine until next boot."
else
  "${cw_ROOT}"/etc/handlers/gpu-support/initialize
fi
