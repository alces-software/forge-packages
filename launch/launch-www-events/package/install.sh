#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Flight Launch web configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/launch-www/configure"
  "${cw_ROOT}/etc/handlers/launch-www/start"
fi
