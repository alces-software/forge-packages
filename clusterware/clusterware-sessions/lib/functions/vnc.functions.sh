#==============================================================================
# Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
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
#ALCES_META
# Refer to `clusterware/scripts/development/propagate`.
#path=/opt/clusterware/lib/functions/vnc.functions.sh
#ALCES_META_END

require xdg
require repo
require files

cw_VNC_SESSIONSDIR="$(xdg_cache_home)"/clusterware/sessions
# XXX
cw_VNC_VNCSERVER="${cw_ROOT}/libexec/session/share/vncserver"
cw_VNC_BINDIR="${cw_ROOT}/opt/tigervnc/bin"
cw_VNC_VNCPASSWD="${cw_VNC_BINDIR}/vncpasswd"
cw_SESSION_dir="${cw_ROOT}/etc/sessions"
cw_SESSION_DEFAULT_REPO="base"
cw_SESSION_DEFAULT_REPO_URL="${cw_SESSION_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-sessions}"
cw_SESSION_REPODIR="${cw_ROOT}/var/lib/sessions/repos"

if [ -f "${cw_ROOT}/etc/session.rc" ]; then
    . "${cw_ROOT}/etc/session.rc"
fi

vnc_create_password() {
    dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | tr -d '/+' | cut -c1-8
}

vnc_create_password_file() {
    local password sessiondir
    password="$1"
    sessiondir="$2"

    echo "${password}" | "${cw_VNC_VNCPASSWD}" -f > "${sessiondir}/password.dat"
    chmod 0600 "${sessiondir}/password.dat"
    files_mark_tempfile "${sessiondir}/password.dat"
}

vnc_session_start() {
    local password geometry sessiondir
    password="$1"
    geometry="$2"
    sessiondir="$3"
    shift 3

    vnc_create_password_file "${password}" "${sessiondir}"
    vnc_start_server "${geometry}" "${sessiondir}" "$@"
}

vnc_start_server() {
    local geometry sessiondir
    geometry="$1"
    sessiondir="$2"
    shift 2

    # Set session geometry variable for VNC server process so the session
    # scripts for session types which do not obey the VNC server's geometry
    # parameter can be forced to resize to the given geometry.
    if files_lock clusterware.session 5r 60; then
        cw_SESSION_geometry="${geometry}" $cw_VNC_VNCSERVER -autokill \
                           -sessiondir "${sessiondir}" \
                           -sessionscript "${sessiondir}/session.sh" \
                           -vncpasswd "${sessiondir}/password.dat" \
                           -exedir "${cw_VNC_BINDIR}" \
                           -geometry "${geometry}" \
                           "$@" 2>"${sessiondir}/vncserver.err" > "${sessiondir}/vncserver.out" 5<&-
        files_unlock 5r
        files_mark_tempfile "${sessiondir}/vncserver.out"
        files_mark_tempfile "${sessiondir}/vncserver.err"
    else
        return 1
    fi
}

vnc_read_vars() {
    local sessiondir
    sessiondir="$1"
    grep "^{EVAL}" "${sessiondir}/vncserver.out" | cut -c7-
}

vnc_write_vars_file() {
    local sessionid host access_host display port password websocket metadata_file sessiontype
    sessionid="$1"
    host="$2"
    access_host="$3"
    display="$4"
    port=$(($display+5900))
    password="$5"
    websocket="$6"
    sessiontype="$7"
    vpn_address="$8"

    metadata_file="${cw_VNC_SESSIONSDIR}/${sessionid}/metadata.vars.sh"

    files_mark_tempfile "${metadata_file}"

    cat <<EOF > "${metadata_file}"
vnc[DISPLAY]="${display}"
vnc[PORT]="${port}"
vnc[PASSWORD]="${password}"
vnc[HOST]="${host}"
vnc[HOSTNAME]="$(hostname -s)"
vnc[ACCESS_HOST]="${access_host}"
vnc[WEBSOCKET]="${websocket}"
vnc[TYPE]="${sessiontype}"
vnc[VPN_ADDRESS]="${vpn_address}"
EOF
    chmod 0600 "${metadata_file}"
}

vnc_write_detail_file() {
    local sessionid detail_file
    sessionid="$1"

    detail_file="${cw_VNC_SESSIONSDIR}/${sessionid}/details.txt"
    files_mark_tempfile "${detail_file}"
    vnc_emit_details "$@" > "${detail_file}"
    chmod 0600 "${detail_file}"
}

vnc_emit_details() {
    local sessionid host access_host display password websocket port \
    sessiontype vpn_address primary_address alternative_access_details \
    access_info

    sessionid="$1"
    host="$2"
    access_host="$3"
    display="$4"
    password="$5"
    websocket="$6"
    port=$(($display+5900))
    sessiontype="$7"
    vpn_address="$8"

    # If we have been given an address on the VPN we want to show this as the
    # recommended access address, as it's more secure by default. Note: if we
    # have not been given this the access_host might still be an address on the
    # VPN, e.g. if this is a node without a public IP.
    primary_address="${vpn_address:-$access_host}"

    # The primary address to show may or may not be on the cluster VPN; we
    # should show an appropriate method in each case.
    if [[ $primary_address =~ ^10. ]];then
      access_info=$(cat <<EOF
Depending on your client, you can securely connect to the session while
connected to your cluster VPN using:
EOF
      )

    else
      access_info=$(cat <<EOF
Depending on your client, you can (insecurely by default) connect to the
session using:
EOF
)
    fi

    host_str="        Host: ${access_host}"
    if [ "${access_host}" != "${host}" ]; then
        host_str="$host_str
Service host: ${host}"
    fi

    # If we have an address on the VPN we want to show this, and also show the
    # alternative, default insecure access method without using this.
    if [ -n "$vpn_address" ]; then
      host_str="$host_str
 VPN address: ${vpn_address}"

    alternative_access_details="$(cat <<EOF

Alternatively, you can connect to the session directly using:

  vnc://${USER}:${password}@${access_host}:${port}
  ${access_host}:${port}
  ${access_host}:${display}

Note that this method is insecure by default, unless you take steps to secure
your VNC connection.

EOF
)"
    fi

    cat <<EOF
VNC server started:
    Identity: $sessionid
        Type: $sessiontype
$host_str
        Port: $port
     Display: $display
    Password: $password
   Websocket: $websocket

${access_info}

  vnc://${USER}:${password}@${primary_address}:${port}
  ${primary_address}:${port}
  ${primary_address}:${display}
${alternative_access_details}

If prompted, you should supply the following password: ${password}

EOF
}

vnc_kill_server() {
    local sessiondir
    sessiondir="$1"
    $cw_VNC_VNCSERVER -kill -sessiondir ${sessiondir} &> "${sessiondir}/vncserver.kill.log"
}

vnc_cleanup() {
    local display sessiondir
    display="$1"
    sessiondir="$2"

    action_debug "terminating VNC server process (:${display})"
    vnc_kill_server "${sessiondir}" &> "${sessiondir}/vncserver.kill.log"
    files_mark_tempfile "${sessiondir}/vncserver.kill.log"
}

vnc_session_clean() {
    local sessiondir skip_running sessionid shortid pidfile
    local -A vnc
    if [ "$1" == "--skip-running" ]; then
        skip_running=true
        shift
    fi
    sessiondir="$1"

    if [ -d "$sessiondir" ]; then
        pidfile="$sessiondir"/vncserver.pid
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')

        if [ -f "${sessiondir}/starting.txt" ]; then
            if [ ! "$skip_running" ]; then
                action_warn "session $shortid is starting up - use kill to terminate first!"
            fi
        elif [ -f "$pidfile" ]; then
            if [ -f "${sessiondir}"/metadata.vars.sh ]; then
                . "${sessiondir}"/metadata.vars.sh
                # check if current host
                if [ "$(hostname -s)" == "${vnc[HOSTNAME]}" ]; then
                    if ! pgrep -F $pidfile &>/dev/null; then
                        # not running; clean
                        action_warn "cleaned session $shortid"
                        rm -rf "$sessiondir"
                    elif [ ! "$skip_running" ]; then
                        action_warn "session $shortid is still running - use kill to terminate first!"
                    fi
                elif [ ! "$skip_running" ]; then
                    action_warn "session ${shortid} is running on remote host ${vnc[HOSTNAME]}"
                fi
            else
                action_warn "cleaned session $shortid"
                rm -rf "$sessiondir"
            fi
        elif [ ! -f "$pidfile" ] || ! pgrep -F $pidfile &>/dev/null; then
            action_warn "cleaned session $shortid"
            rm -rf "$sessiondir"
        elif [ ! "$skip_running" ]; then
            action_warn "session $shortid is still running - use kill to terminate first!"
        fi
    else
        action_warn "no matching session could be found"
    fi
}

vnc_session_kill() {
    local sessiondir sessionid shortid pidfile
    local -A vnc
    sessiondir="$1"
    if [ -d "$sessiondir" ]; then
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')
        pidfile="$sessiondir"/vncserver.pid
        if [ -f "$pidfile" ]; then
            if [ -f "${sessiondir}"/metadata.vars.sh ]; then
                . "${sessiondir}"/metadata.vars.sh
                # check if current host
                if [ "$(hostname -s)" == "${vnc[HOSTNAME]}" ]; then
                    if ! pgrep -F $pidfile &>/dev/null; then
                        action_warn "session ${shortid} is already dead - use clean to cleanup"
                    else
                        if vnc_kill_server "${sessiondir}" &>/dev/null; then
                            action_warn "session ${shortid} has been terminated"
                        else
                            action_die "session ${shortid} could not be terminated" 1
                        fi
                    fi
                else
                    action_warn "session ${shortid} is running on remote host ${vnc[HOSTNAME]}"
                fi
            else
                action_warn "session ${shortid} is already dead - use clean to cleanup"
            fi
        else
            action_warn "session ${shortid} is already dead - use clean to cleanup"
        fi
    else
        action_warn "no matching session could be found"
    fi
}

vnc_session_wait() {
    local sessiondir sessionid shortid pidfile
    sessiondir="$1"
    if [ -d "$sessiondir" ]; then
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')
        pidfile="$sessiondir"/vncserver.pid
        action_warn "waiting for session ${shortid} to complete..."
        while [ -f "$pidfile" ] && pgrep -F $pidfile &>/dev/null; do
            sleep 1
        done
        action_warn "session ${shortid} completed at $(date "+%Y-%m-%d %H:%M:%S")"
    fi
}

vnc_find_sessiondir() {
    local sessionid sessiondir
    sessionid="$1"
    sessiondir=$(echo "${cw_VNC_SESSIONSDIR}"/${sessionid}-*)
    if [ ! -d "${sessiondir}" ]; then
        sessiondir=$(echo "${cw_VNC_SESSIONSDIR}"/${sessionid})
    fi
    if [ ! -d "${sessiondir}" ]; then
        return 1
    else
        echo "${sessiondir}"
    fi
}

vnc_each_sessiondir() {
    local callback sessiondir
    callback="$1"
    for sessiondir in "${cw_VNC_SESSIONSDIR}"/*; do
        if [ -d "$sessiondir" ]; then
            ${callback} "${sessiondir}"
        fi
    done
}

vnc_no_sessions() {
    local sessiondir
    for sessiondir in "${cw_VNC_SESSIONSDIR}"/*; do
        if [ -d "$sessiondir" ]; then
            break
        else
            return 0
        fi
    done
    return 1
}

vnc_sessions_dir() {
    echo "${cw_VNC_SESSIONSDIR}"
}

session_is_enabled() {
    repo_plugin_is_enabled "${cw_SESSION_dir}" "$@"
}

session_repo_exists() {
    repo_exists "${cw_SESSION_REPODIR}" "$@"
}

session_exists() {
    repo_plugin_exists "${cw_SESSION_REPODIR}" "$@"
}

session_install() {
    repo_plugin_install "${cw_SESSION_REPODIR}" "$@"
}

session_enable() {
    repo_plugin_enable "${cw_SESSION_REPODIR}" "${cw_SESSION_dir}" "$@"
}

session_disable() {
    repo_plugin_disable "${cw_SESSION_dir}" "$@"
}

session_check_quota() {
    local active sessiondir
    local -A vnc
    if [ "${cw_SESSION_quota:-0}" == "0" ]; then
        return 0
    else
        active=0
        for sessiondir in "${cw_VNC_SESSIONSDIR}"/*; do
            if [ -d "$sessiondir" ]; then
                if [ -f "${sessiondir}"/metadata.vars.sh ]; then
                    . "${sessiondir}"/metadata.vars.sh
                    if [ "$(hostname -s)" == "${vnc[HOSTNAME]}" ]; then
                        active=$(($active+1))
                    fi
                fi
            fi
        done
        [ "${active}" -lt "${cw_SESSION_quota}" ]
    fi
}
