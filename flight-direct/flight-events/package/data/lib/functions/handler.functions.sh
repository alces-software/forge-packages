#==============================================================================
# Copyright (C) 2015-2018 Stephen F. Norledge and Alces Software Ltd.
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
require ruby
require repo
require log

cw_HANDLER_PLUGINDIR="${cw_ROOT}/etc/events"
export PLUGIN_PATH="$cw_HANDLER_PLUGINDIR"
cw_HANDLER_HOOK_RUNNER="${cw_ROOT}/opt/pluginhook/bin/pluginhook"
cw_HANDLER_BROADCASTER="${cw_ROOT}/opt/serf/bin/serf"
cw_HANDLER_name="$(cd "$(dirname "$0")" && basename "$(pwd)" | sed 's/^[0-9]*-//g'):$(basename "$0")"

handler_run_hook() {
    local event
    event="$1"
    shift
    "$cw_HANDLER_HOOK_RUNNER" "$event" "$@"
}

handler_broadcast() {
    local event quietly
    if [ "$1" == "--quiet" ]; then
        quietly="true"
        shift
    fi
    event="$1"
    if [ -f "${cw_ROOT}"/etc/config/cluster/auth.rc ]; then
        . "${cw_ROOT}"/etc/config/cluster/auth.rc
        if [ "$quietly" ]; then
            "${cw_HANDLER_BROADCASTER}" event \
              -coalesce=false \
              -rpc-auth="${cw_CLUSTER_auth_token}" \
              "${event}" "$*" &>/dev/null
        else
            "${cw_HANDLER_BROADCASTER}" event \
              -coalesce=false \
              -rpc-auth="${cw_CLUSTER_auth_token}" \
              "${event}" "$*"
        fi
    else
        return 1
    fi
}

handler_query() {
    local query
    query="$1"
    if [ -f "${cw_ROOT}"/etc/config/cluster/auth.rc ]; then
        . "${cw_ROOT}"/etc/config/cluster/auth.rc
        "${cw_HANDLER_BROADCASTER}" query -format=json \
            -rpc-auth="${cw_CLUSTER_auth_token}" \
            "${query}" "$*"
    else
        return 1
    fi
}

handler_tee() {
    local input
    read input
    if [ -z "$input" ]; then
        "$@" 2>&1 | log_blob "${cw_LOG_default_log}" "${cw_HANDLER_name}"
    else
        "$@" <<< "${input}" 2>&1 | log_blob "${cw_LOG_default_log}" "${cw_HANDLER_name}"
        echo "${input}"
        while read input; do
            "$@" <<< "${input}" 2>&1 | log_blob "${cw_LOG_default_log}" "${cw_HANDLER_name}"
            echo "${input}"
        done
    fi
}

handler_iptables_insert() {
    if ! iptables -C "$@" &>/dev/null; then
        echo "Adding iptables rule: $*"
        iptables -I "$@"
    else
        echo "iptables rule already exists: $*"
    fi
}

handler_iptables_delete() {
    if iptables -C "$@" &>/dev/null; then
        echo "Removing iptables rule: $*"
        iptables -D "$@"
    else
        echo "iptables rule not present: $*"
    fi
}

handler_add_libdir() {
    local dir libdir
    libdir="$1"
    if [ "${libdir:0:1}" == "/" ]; then
        cw_LIBPATH="${cw_LIBPATH}:${libdir}"
    else
        libdir="/$1"
        dir=$(cd "$(dirname "${BASH_SOURCE[-1]}")" && pwd)
        cw_LIBPATH="${cw_LIBPATH}:${dir}${libdir}"
    fi
}

handler_run_helper() {
    local dir helper
    helper="$1"
    shift
    if [ "${helper:0:1}" != "/" ]; then
        dir=$(handler_dir)/
    fi
    "${dir}${helper}" "$@"
}

handler_dir() {
    cd "$(dirname "${BASH_SOURCE[-1]}")" && pwd
}
