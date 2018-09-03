#: SYNOPSIS: Sync files from the cache
#: ROOT: true

require 'flight_syncer'
require 'yaml'
require 'ostruct'
require 'hashie'

# Manages the client side configurations
YAML_File = Struct.new(:path) do
  def update
    yield data if block_given?
    save
  end

  def data
    @data ||= Hashie::Mash.new(raw_load)
  end

  def save
    FileUtils.mkdir_p File.dirname(path)
    File.write(path, YAML.dump(data.to_hash))
  end

  private

  def raw_load
    File.exists?(path) ? YAML.load_file(path) : {}
  end
end
Config = YAML_File.new(
  File.join(ENV['FL_ROOT'], 'var/lib/syncer/client.yaml')
)

# The cache commands are used to modify the sync manifest on the server
class Cache < Thor
  include Loki::ThorExt

  desc 'file PATH', 'Add a file to the local cache'
  METAFILE_PARAMS = {
    path: 'The sync path of the file',
    identifier: 'A unique refernce to the file, defaults to the basename',
    mode: 'Sets the file permissions as an octal',
    owner: 'Sets the files owner',
    group: 'Sets the files group'
  }.each do |key, option_desc|
    method_option key, desc: option_desc
  end
  long_desc <<-LONGDESC
    The `sync cache file` comamand will add a file to the sync cache. The
    file is stored by the given `--identifier` input. It will default to
    the base filename if missing.

    The following flags are also optional. They will be inferred from the
    source file if missing: --path, --mode, --owner, --group
  LONGDESC
  loki_command(:file) do |path|
    content = File.read(path)
    params = options.symbolize_keys.select do |k, _v|
      METAFILE_PARAMS.keys.include?(k)
    end
    FlightSyncer::MetaFile.build_from_file(path, **params)
                          .save_to_cache(content)
  end

  desc 'group NAME FILES...', 'Add files to a group'
  long_desc <<-LONGDESC
    The `sync cache group` command allows for multiple files to be synced as
    a group. The command adds existing files (by identifier) to the group.

    The command will not delete files, so it is safe run the command multiple
    times with the same group
  LONGDESC
  loki_command(:group) do |group, *files|
    FlightSyncer::SyncManifest.update do |manifest|
      manifest.add_files_to_group(group, *files)
    end
  end
end

# Only show the cache commands if the public static folder has been defined
if FlightConfig.get('public-dir')
  desc 'cache SUBCOMMAND ...ARGS', 'Manage the anvil file cache server'
  subcommand 'cache', Cache
end

class Add < Thor
  include Loki::ThorExt

  desc 'files IDENTIFIERS...', 'Add files to be synced'
  loki_command(:files) do |*identifiers|
    Config.update do |data|
      data.files = (data.files || []) | identifiers
    end
  end

  desc 'groups NAMES...', 'Add groups to be synced'
  loki_command(:groups) do |*names|
    Config.update do |data|
      data.groups = (data.groups || []) | names
    end
  end
end
desc 'add SUBCOMMAND ...ARGS', 'Add files to be synced'
subcommand 'add', Add

class List < Thor
  include Loki::ThorExt

  desc 'files', 'List the files to be synced'
  loki_command(:files) do
    puts Config.data.files
  end

  desc 'groups', 'List the groups to be synced'
  loki_command(:groups) do
    puts Config.data.groups
  end
end
desc 'list SUBCOMMAND ...ARGS', 'List the files/groups to be synced'
subcommand 'list', List

desc 'run-sync', 'Syncs all the files and groups'
loki_command(:run_sync) do
  FlightSyncer::SyncManifest.remote do |manifest|
    files = Array.wrap(Config.data.groups)
                 .map { |group| manifest.files_in_group(group) }
                 .push(Array.wrap(Config.data.files))
                 .flatten
                 .uniq
    files.each do |identifier|
      if (metafile = manifest.get_metafile(identifier)).nil?
        $stderr.puts <<-WARN.strip_heredoc
          Warning: Could not locate '#{identifier}' file in sync manifest
        WARN
      else
        begin
          metafile.save_from_cache
        rescue => e
          $stderr.puts <<-WARN.strip_heredoc
            Warning: Failed to sync '#{identifier}'
            Error: #{e.message}
          WARN
        end
      end
    end
  end
end

