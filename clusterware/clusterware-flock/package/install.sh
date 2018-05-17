#!/bin/bash

cp -R data/opt/clusterware/* "${cw_ROOT}"

cat <<EOF >> "${cw_ROOT}"/etc/fshelper.rc

cw_FS_flight_desc="Flight Shares"
cw_FS_flight_root="/mnt/flight/users"
cw_FS_flight_mode="700"
cw_FS_flight_scheme="username"
EOF

sed -i -e 's/^\(cw_FS_roots=(.*\))$/\1 flight)/' \
    "${cw_ROOT}"/etc/fshelper.rc

cat <<EOF > "${cw_ROOT}"/etc/flock.rc
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################
#cw_FLOCK_mnt=/mnt/flight
EOF
