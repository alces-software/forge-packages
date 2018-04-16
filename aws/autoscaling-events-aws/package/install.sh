#!/bin/bash

cp -R data/* "${cw_ROOT}"

cat <<\EOF > "${cw_ROOT}"/etc/motd.d/60-autoscaling.sh
################################################################################
##
## Alces Clusterware - Clusterware MOTD banner
## Copyright (c) 2016 Alces Software Ltd
##
################################################################################
# Determine what kind of node we are
if [ -f "${cw_ROOT}"/etc/config/cluster/instance.rc ]; then
  eval $(grep '^cw_INSTANCE_role=' "${cw_ROOT}"/etc/config/cluster/instance.rc)
fi
if [ "${cw_INSTANCE_role}" == "master" ]; then
  # We're a master, if autoscaling is enabled output a message
  if [ -f "${cw_ROOT}"/etc/config/cluster/instance-aws.rc ]; then
    eval $(grep '^cw_INSTANCE_aws_autoscaling=' "${cw_ROOT}"/etc/config/cluster/instance-aws.rc)
    if [ "${cw_INSTANCE_aws_autoscaling}" == 'enabled' ]; then
      cat <<MSG

$(echo -e "\e[1;33m")================
 AUTOSCALING ON
================$(echo -e "\e[0m")
This cluster is currently configured to autoscale.  When jobs are waiting in
the queue additional instances will be started.  Refer to the docs for more
information about autoscaling: $(echo -e "\e[4m")http://docs.alces-flight.com$(echo -e "\e[24m")
MSG
      if sudo -l | grep -q ' ALL$'; then
        cat <<MSG

You can control autoscaling using the "alces configure autoscaling" command.
MSG
      fi
    fi
    unset cw_INSTANCE_aws_autoscaling
  fi
fi
unset cw_INSTANCE_role
EOF

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring autoscaling configuration until next boot."
else
  "${cw_ROOT}"/etc/handlers/autoscaling/configure

  _handle_members() {
    shift  # Gets rid of the '--' that member_each starts with
    echo "$@" | "${cw_ROOT}/etc/handlers/autoscaling/member-join"
  }

  require member
  member_each _handle_members

fi
