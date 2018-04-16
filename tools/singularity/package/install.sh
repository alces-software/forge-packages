#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Singularity configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/configure-singularity/configure" # XXX parameters
fi
