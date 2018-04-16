#!/bin/bash
#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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

main() {
    files_load_config auth config/cluster
    if ! type -f apg &>/dev/null; then
        if distro_enable_repository epel; then
            yum install -y -e0 apg
        fi
    fi
    if type -f apg &>/dev/null; then
        password=$(echo $(apg -M l -m5 -x5 -n3 -a0) | tr ' ' '-')
    else
        password="$(dd if=/dev/urandom bs=24 count=2 2>/dev/null | base64 | cut -c1-16)"
    fi

    admin_user=$(id -un 1000)
    echo "${admin_user}:${password}" | chpasswd
    chage -d0 "${admin_user}"

    # Disable use of PAM so users logging in with a valid SSH key
    # aren't prompted to change the password.
    sed -r -i -e 's/^#?UsePAM yes/UsePAM no/g' \
        /etc/ssh/sshd_config
    distro_restart_service sshd

    # Add password to signal.rc
    signal_data="Initial password=${password}"
    ruby_run <<RUBY
content = if File.exists?('${cw_ROOT}/etc/signal.rc')
  File.read('${cw_ROOT}/etc/signal.rc').gsub!(%(cw_SIGNAL_data="),%(cw_SIGNAL_data="${signal_data};))
else
  %(cw_SIGNAL_data="${signal_data}")
end
File.write('${cw_ROOT}/etc/signal.rc', content, perm: 0600)
RUBY
}

setup
require files
require ruby
require distro

main "$@"
