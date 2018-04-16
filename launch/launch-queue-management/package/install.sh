#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Flight Launch queue management configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/launch-queue-management/configure"
  "${cw_ROOT}/etc/handlers/launch-queue-management/node-started"
fi
