#!/bin/bash

cp -R data/* "${cw_ROOT}"

cat <<EOF > "${cw_ROOT}"/etc/sudoers.d/clusterware-handler-session-firewall
################################################################################
##
## Alces Clusterware - sudoers configuration file
## Copyright (c) 2015-2016 Alces Software Ltd
##
################################################################################
Defaults!${cw_ROOT}/etc/handlers/session-firewall/session-* !requiretty
ALL ALL=(root) NOPASSWD:${cw_ROOT}/etc/handlers/session-firewall/session-*
EOF
chmod 0400 "${cw_ROOT}"/etc/sudoers.d/clusterware-handler-session-firewall
