#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

require 'flight_config'
require 'thor/group'

class Snapshot < Thor::Group
  # NOTE: The following methods are ran in the order they have been defined
  # Some of the tasks are order dependent (e.g. download/import)
  def database_setup
    run_rake('db:setup')
  end

  def download_packages
    puts 'Downloading packages...'
    run_rake('packages:download')
  end

  def import_packages
    puts 'Importing the packages...'
    run_rake('packages:import')
  end

  def enable_systemctl
    system('systemctl enable anvil')
  end

  private

  def run_rake(command)
    dir = File.join(FlightDirect.root_dir, 'opt/anvil')
    system("cd #{dir} && rake #{command}")
  end
end

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) do |address|
  ENV['RAILS_ENV'] = 'snapshot'
  ENV['ANVIL_BASE_URL'] = "http://#{address}"
  ENV['ANVIL_UPSTREAM'] = 'https://forge-api.alces-flight.com'
  ENV['ANVIL_LOCAL_DIR'] = File.expand_path('opt/anvil/public',
                                            FlightDirect.root_dir)
  Snapshot.start
end

