#!/bin/bash
#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd.
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
setup() {
    local a xdg_config
    IFS=: read -a xdg_config <<< "${XDG_CONFIG_HOME:-$HOME/.config}:${XDG_CONFIG_DIRS:-/etc/xdg}"
    for a in "${xdg_config[@]}"; do
        if [ -e "${a}"/clusterware/config.rc ]; then
            source "${a}"/clusterware/config.rc
            break
        fi
    done
    if [ -z "${cw_ROOT}" ]; then
        echo "$0: unable to locate clusterware configuration"
        exit 1
    fi
    kernel_load
}

setup

require distro
if distro_enable_repository epel; then
  yum install -y -e0 nodejs npm
  if [ $? -ne 0 ] ; then
    # The epel repository no longer contains the http-parser dependency
    # for nodejs.  For Centos7.4 the package will be available in the base
    # repo, but that hasn't been released at the time of commenting, so
    # let's workaroudn the failure.
    #
    # See https://bugs.centos.org/view.php?id=13669&nbn=1 for more details.
    rpm -ivh https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm
    yum install -y -e0 nodejs npm
  fi
else
  echo "Sorry, the EPEL repository is not available."
  exit 1
fi

# XXX We should check that HTTPS access is enabled and bail if not.  We
# shouldn't run the web terminal over HTTP.
service_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

require handler

if handler_is_enabled launch-www; then
    "${cw_ROOT}"/libexec/share/www-add-attributes \
                "${service_root}"/web-attributes.json.tpl
fi

cp -pR data/* "${cw_ROOT}"

enable_alces_web_terminal_daemon() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
        init/systemd/clusterware-web-terminal.service \
        > /etc/systemd/system/clusterware-web-terminal.service
    systemctl enable clusterware-web-terminal.service
}

create_metadata_file() {
  require files
  require network

  local host https_port terminal_url socket_io_path
  files_load_config --optional access
  files_load_config --optional www

  host="${cw_ACCESS_fqdn:-$(network_get_public_hostname)}"
  https_port="${cw_WWW_https_port:-443}"
  if [ "$https_port" != "443" ]; then
      https_port=":${https_port}"
  else
      https_port=""
  fi
  terminal_url="https://${host}${https_port}/pty"
  socket_io_path="/terminal/socket.io"

  cat <<EOF > "${cw_ROOT}"/etc/meta.d/web-terminal.rc
: '
: SYNOPSIS: Alces Web Terminal access details
: HELP: Display information about the Alces Web Terminal service configuration for this cluster.
: '
################################################################################
##
## Alces Clusterware - Metadata file
## Copyright (c) 2016 Alces Software Ltd
##
################################################################################
EOF
  echo "cw_META_web_terminal_https_desc=\"HTTPS access point\"" >> "${cw_ROOT}"/etc/meta.d/web-terminal.rc
  echo "cw_META_web_terminal_https=\"${terminal_url}\"" >> "${cw_ROOT}"/etc/meta.d/web-terminal.rc
  echo "cw_META_web_terminal_socket_io_path_desc=\"Socket.IO path\"" >> "${cw_ROOT}"/etc/meta.d/web-terminal.rc
  echo "cw_META_web_terminal_socket_io_path=\"${socket_io_path}\"" >> "${cw_ROOT}"/etc/meta.d/web-terminal.rc
}

create_metadata_file
enable_alces_web_terminal_daemon
distro_start_service clusterware-web-terminal
distro_restart_service clusterware-www
