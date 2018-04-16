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

package_name='launch-web-terminal'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

pushd "${temp_dir}" > /dev/null

require distro

if distro_enable_repository epel; then
  yum install -y -e0 nodejs npm gcc-c++
else
  echo "Sorry, the EPEL repository is not available."
  exit 1
fi
dest=data/opt/alces-web-terminal

alces module load services/git

# XXX We should probably rename the flight-tutorials-server github repo to
# alces-web-terminal.
curl -L \
  "https://github.com/alces-software/flight-tutorials-server/tarball/master" \
  -o /tmp/alces-web-terminal.tar.gz
rm -rf "${dest}"
mkdir -p "${dest}"
tar -C "${dest}" --strip-components=1 -xzf /tmp/alces-web-terminal.tar.gz

pushd "${dest}"

# Update configuration values.
_JQ="${cw_ROOT}"/opt/jq/bin/jq
tmpfile="$(mktemp /tmp/alces-web-terminal.XXXXXXXX)"
$_JQ --arg port 26399 --arg path "/terminal/socket.io" \
    '.port = $port | .socketIO.path = $path' \
    config.json > "${tmpfile}"
chmod a+r "${tmpfile}"
mv "${tmpfile}" config.json

rm -rf node_modules
npm install --unsafe-perm
popd
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
