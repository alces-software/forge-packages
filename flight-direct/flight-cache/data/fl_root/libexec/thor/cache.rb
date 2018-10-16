#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

require 'flight_config'
require 'thor/group'

class Snapshot < Thor::Group
  def run_snapshot
    dir = File.join(FlightDirect.root_dir, 'opt/anvil')
    exec("cd #{dir} && rake packages:snapshot")
  end

  def enable_systemctl
    exec('systemctl enable anvil')
  end
end

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) do |address|
  ENV['ANVIL_BASE_URL'] = "http://#{address}"
  ENV['RAILS_ENV'] = 'snapshot'
  Snapshot.start
end

