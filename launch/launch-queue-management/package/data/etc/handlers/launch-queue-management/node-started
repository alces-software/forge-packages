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
  export cw_UI_disable_spinner=true
  ruby_run <<RUBY
require 'yaml'

def log(message)
  @log ||= File.open('/var/log/clusterware/queue-creator.log', 'a')
  @log.puts("#{Time.now.strftime('%b %e %H:%M:%S')} #{message}")
end

class Retry < RuntimeError; end
retries = 0

p_file = '${cw_ROOT}/etc/personality.yml'
begin
  if File.exists?(p_file)
    personality = YAML.load_file(p_file)
    if queues = personality['queues']
      queues.each do |spec, params|
        desired = params['desired'].to_s
        min = params['min'].to_s
        max = params['max'].to_s
        log("Adding queue: #{spec} (#{desired}/#{min}-#{max})")
        begin
          IO.popen(['${_ALCES}', 'compute', 'addq',
                    spec, desired, min, max,
                    :err=>[:child, :out]]) do |io|
            while !io.eof?
              line = io.readline
              log(line)
              raise Retry.new if line =~ /operation in progress/
            end
          end
        rescue Retry
          if (retries += 1) < 20
            log('Operation in progress; retrying in 6s...')
            sleep 6
            retry
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
require ruby

_ALCES="${cw_ROOT}"/bin/alces

main "$@"
