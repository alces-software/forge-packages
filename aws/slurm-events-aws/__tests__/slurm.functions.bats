#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
if ! type kernel_load &>/dev/null; then
    kernel_load() { source "${cw_ROOT}/lib/clusterware.kernel.sh"; }
fi

# Rename standard Clusterware setup function to not conflict with bats' setup
# function.
clusterware_setup() {
    local a xdg_config
    IFS=: read -a xdg_config <<< "${XDG_CONFIG_HOME:-$HOME/.config}:${XDG_CONFIG_DIRS:-/etc/xdg}"
    for a in "${xdg_config[@]}"; do
        if [ -e "${a}"/clusterware/config.vars.sh ]; then
            source "${a}"/clusterware/config.vars.sh
            break
        fi
    done
    if [ -z "${cw_ROOT}" ]; then
        echo "$0: unable to locate clusterware configuration"
        exit 1
    fi
    kernel_load
}

clusterware_setup
require handler

handler_add_libdir "${BATS_CWD}/../share"
require slurm-handler

setup() {
  # Create temporary slurm.conf file for each test.
  export cw_CLUSTER_SLURM_config="$(mktemp /tmp/slurm.conf.XXXXXXXX)"
}

initial_slurm_config="$(cat <<-'EOF'
ConfigBefore
ConfigBetween
PartitionName=all Nodes=ALL Default=YES MaxTime=UNLIMITED
ConfigAfter
EOF
)"

two_node_slurm_config="$(cat <<-'EOF'
ConfigBefore
ConfigBetween
PartitionName=all Nodes=ALL Default=YES MaxTime=UNLIMITED
ConfigAfter
NodeName=node01 CPUs=2
NodeName=node02 CPUs=4
EOF
)"

@test "slurm functions are loaded" {
    type slurm_log
}

@test "slurm_add_compute_node adds nodes to config" {
  echo "${initial_slurm_config}" > "${cw_CLUSTER_SLURM_config}"

  run handler_run_helper ${BATS_CWD}/../share/add-node "node01.cluster" "2"

  run cat "${cw_CLUSTER_SLURM_config}"
  [ "${lines[-1]}" = 'NodeName=node01 CPUs=2' ]

  run handler_run_helper ${BATS_CWD}/../share/add-node "node02.cluster" "4"
  cat "${cw_CLUSTER_SLURM_config}"

  run cat "${cw_CLUSTER_SLURM_config}"
  [ "${lines[-2]}" = 'NodeName=node01 CPUs=2' ]
  [ "${lines[-1]}" = 'NodeName=node02 CPUs=4' ]
}


@test "slurm_add_compute_node will not add an already present node" {
  echo "${two_node_slurm_config}" > "${cw_CLUSTER_SLURM_config}"

  run handler_run_helper ${BATS_CWD}/../share/add-node "node01.cluster" "2"

  run cat "${cw_CLUSTER_SLURM_config}"
  [ "${lines[-2]}" = 'NodeName=node01 CPUs=2' ]
  [ "${lines[-1]}" = 'NodeName=node02 CPUs=4' ]
}

@test "slurm_remove_compute_node removes nodes from config" {
  echo "${two_node_slurm_config}" > "${cw_CLUSTER_SLURM_config}"

  run handler_run_helper ${BATS_CWD}/../share/prune-node "node02.cluster"

  run cat "${cw_CLUSTER_SLURM_config}"
  [ "${lines[-1]}" = 'NodeName=node01 CPUs=2' ]

  run handler_run_helper ${BATS_CWD}/../share/prune-node "node01.cluster"

  run cat "${cw_CLUSTER_SLURM_config}"
  [ "${lines[-1]}" = 'ConfigAfter' ]
}

teardown() {
  # Remove test's temporary slurm.conf and slurm.conf lock file.
  rm -f ${cw_CLUSTER_SLURM_config}{,.lock}
}
