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
  files_load_config instance config/cluster
  if [ "${cw_INSTANCE_role}" != "master" ]; then
      return 0
  fi

  export cw_UI_disable_spinner=true
  export HOME=/root
  ruby_run <<RUBY
require 'yaml'

def log(message)
  @log ||= File.open('/var/log/clusterware/software-installer.log', 'a')
  @log.puts("#{Time.now.strftime('%b %e %H:%M:%S')} #{message}")
end

def run(*args)
  IO.popen(*args, :err=>[:child, :out]) do |io|
    log(io.readline) until io.eof?
  end
end

p_file = '${cw_ROOT}/etc/personality.yml'
begin
  if File.exists?(p_file)
    personality = YAML.load_file(p_file)
    if software = personality['software']
      if software['gridware']
        log("Gridware packages requested, ensuring Gridware is installed")
        run(['${_ALCES}', 'forge', 'install', 'alces/gridware'])
        run(['${_ALCES}', 'forge', 'install', 'alces/gridware-events-aws'])
        software['gridware'].each do |pkg|
          log("Installing package: #{pkg}")
          run(['${_ALCES}', 'gridware', 'install',
                    '--yes', pkg])
        end
      end

      if containers = software['docker']
        log("Enabling docker")
        run(['${_ALCES}', 'forge', 'install',
                  'alces/docker'])

        containers.each do |container|
          log("Pulling container: #{container}")
          run(['${_ALCES}', 'gridware', 'docker',
                  'pull', container])
          if \$?.success? &&
            (!container.include?('/') ||
             match = Regexp.new('^alces/gridware-(.*)').match(container))
            ctr_name = (match && match[1]) || container
            log("Sharing container: #{ctr_name}")
            run(['${_ALCES}', 'gridware', 'docker',
                    'share', ctr_name])
          end
        end
      end
    end
  end
ensure
  @log && @log.close
end
RUBY
}

setup
require distro
require files
require ruby

_ALCES="${cw_ROOT}"/bin/alces

main "$@"
