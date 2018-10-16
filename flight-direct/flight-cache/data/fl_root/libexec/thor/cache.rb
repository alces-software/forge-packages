#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

require 'flight_config'
require 'thor/group'
require 'open-uri'

class Snapshot < Thor::Group
  argument :address, type: :string

  # NOTE: The following methods are ran in the order they have been defined
  # Some of the tasks are order dependent (e.g. download/import)
  def setup
    ENV['RAILS_ENV'] = 'snapshot'
    ENV['ANVIL_BASE_URL'] = "http://#{address}"
    ENV['ANVIL_UPSTREAM'] = 'https://forge-api.alces-flight.com'
    ENV['ANVIL_LOCAL_DIR'] = File.expand_path('opt/anvil/public',
                                              FlightDirect.root_dir)
  end

  def download_flight_direct_bootstrap_script
    puts 'Downloading FlightDirect bootstrap'
    bootstrap_path = File.join(ENV['ANVIL_LOCAL_DIR'],
                               'flight-direct',
                               'bootstrap.sh')
    download(bootstrap_url, bootstrap_path)

    bootstrap_content = File.read(bootstrap_path)
    new_bootstrap_content = bootstrap_content.gsub(
      /# anvil_url=/, "anvil_url=#{ENV['ANVIL_BASE_URL']}"
    )
    FileUtils.rm(bootstrap_path)
    File.write(bootstrap_path, new_bootstrap_content)
  end

  def download_flight_direct_tarball
    puts 'Downloading FlightDirect tarball'
    fd_path = File.join(ENV['ANVIL_LOCAL_DIR'],
                        'flight-direct/flight-direct.tar.gz')
    download(flight_direct_url, fd_path)
  end

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

  def flight_direct_url
    "https://s3-eu-west-1.amazonaws.com/flight-direct/releases/el7/flight-direct-#{FlightDirect::VERSION}.tar.gz"
  end

  def bootstrap_url
    'https://raw.githubusercontent.com/alces-software/flight-direct/master/scripts/bootstrap.sh'
  end

  def download(url, path)
    FileUtils.mkdir_p File.dirname(path)
    case io = open(url)
    when StringIO then File.open(path, 'w') { |f| f.write(io.read) }
    when Tempfile then FileUtils.mv(io.path, path)
    end
  end

  def run_rake(command)
    dir = File.join(FlightDirect.root_dir, 'opt/anvil')
    system("cd #{dir} && rake #{command}")
  end
end

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) { |address| Snapshot.start([address]) }

