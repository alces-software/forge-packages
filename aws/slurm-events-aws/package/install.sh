#!/bin/bash
require files
require member

cp -R data/* "${cw_ROOT}"

_handle_members() {
  shift  # Gets rid of the '--' that member_each starts with
  if [ -f "${cw_ROOT}/etc/handlers/autoscaling/member-join_prescheduler" ]; then
      echo "$@" | "${cw_ROOT}/etc/handlers/autoscaling/member-join_prescheduler"
  fi
  echo "$@" | "${cw_ROOT}/etc/handlers/cluster-slurm/member-join"
}

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Slurm configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/cluster-slurm/configure"
  member_each _handle_members
  if [ -f "${cw_ROOT}/etc/handlers/autoscaling/member-join_prescheduler" ]; then
      mv "${cw_ROOT}/etc/handlers/autoscaling/member-join_prescheduler" "${cw_ROOT}/etc/handlers/autoscaling/member-join"
      mv "${cw_ROOT}/etc/handlers/autoscaling/member-leave_prescheduler" "${cw_ROOT}/etc/handlers/autoscaling/member-leave"
  fi
fi
