#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

ENV['BUNDLE_GEMFILE'] = File.join(FlightDirect.root_dir,
                                  'opt/flight-cache/Gemfile')
require 'bundler/setup'

require 'json'
require 'parallel'
require 'thor/group'
require 'open-uri'

class Snapshot < Thor::Group
  argument :address, type: :string

  # Sets up the environment correctly when the object is initialized
  # NOTE: Not Thread Safe
  def initialize(*_a, **_h, &_b)
    super
    ENV['RAILS_ENV'] = 'snapshot'
    ENV['ANVIL_BASE_URL'] = "http://#{address}"
    ENV['ANVIL_UPSTREAM'] = 'https://forge-api.alces-flight.com'
    ENV['ANVIL_LOCAL_DIR'] = File.expand_path('opt/anvil/public',
                                              FlightDirect.root_dir)
    ENV['ANVIL_IMPORT_DIR'] = File.join(ENV['ANVIL_LOCAL_DIR'], 'packages')
  end

  # NOTE: The following methods are ran in the order they have been defined
  # Some of the tasks are order dependent (e.g. download/import)
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

  def download_git_repos
    ['clusterware-sessions', 'clusterware-storage',
     'gridware-packages-main', 'packager-base', 'gridware-depots'
    ].each do |repo|
      url = "https://github.com/alces-software/#{repo}.git"
      source = "/tmp/repos/#{repo}"
      target = File.join(ENV['ANVIL_LOCAL_DIR'], 'git', "#{repo}.tar.gz")
      print `rm -rf #{source} #{target}`
      print `mkdir -p #{File.dirname(target)}`
      print `git clone #{url} #{source}`
      puts `tar --warning=no-file-changed -C #{source} -czf #{target} .`
    end
    # Renames packager-base to be the volatile repo
    prefix = File.join(ENV['ANVIL_LOCAL_DIR'], 'git')
    packager_src = File.expand_path('packager-base.tar.gz', prefix)
    packager_dst = File.expand_path('gridware-packages-volatile.tar.gz',
                                    prefix)
    FileUtils.mv packager_src, packager_dst
  end

  def database_setup
    run_rake('db:setup')
  end

  def download_packages
    puts 'Downloading packages...'
    raise 'The ANVIL_UPSTREAM has not been set' unless ENV['ANVIL_UPSTREAM']
    raise 'The ANVIL_LOCAL_DIR has not been set' unless ENV['ANVIL_LOCAL_DIR']
    packages = JSON.parse(
      Net::HTTP.get(URI("#{ENV['ANVIL_UPSTREAM']}/v1/packages")),
      object_class: OpenStruct
    )
    Parallel.map(packages.data, in_threads: 10) do |metadata|
      uri = URI.parse(metadata.attributes.packageUrl)
      puts "Downloading: #{uri.to_s}"
      path = package_path(URI.unescape(uri.path))
      download(uri.to_s, path)
    end
  end

  def import_packages
    puts 'Importing the packages...'
    run_rake('packages:import')
  end

  def enable_systemctl
    system('systemctl enable flight-cache')
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
    raise <<-ERROR unless system("cd #{dir} && rake #{command}")
'rake #{command}' exited with non-zero status: #{$?}
ERROR
  end

  def package_path(relative_path)
    File.join(ENV['ANVIL_LOCAL_DIR'], 'packages', relative_path)
  end
end

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) do |address|
  Bundler.with_clean_env { Snapshot.start([address]) }
end

