#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'
require 'flight_config'

# The cache commands are used to modify the sync manifest on the server
class Cache < Thor
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
  def file(path)
    content = File.read(path)
    params = options.symbolize_keys.select do |k, _v|
      METAFILE_PARAMS.keys.include?(k)
    end
    FlightSyncer::MetaFile.build_from_file(path, **params)
                          .save_to_cache(content)
  end

  desc 'group NAME FILES...', 'Add files to a group'
  def group(group, *files)
    FlightSyncer::SyncManifest.update do |manifest|
      manifest.add_files_to_group(group, *files)
    end
  end
end

# Only show the cache commands if the public static folder has been defined
if FlightConfig.get('public-dir')
  desc 'cache SUBCOMMAND ...ARGS', 'Manage the sync server cache'
  subcommand 'cache', Cache
end

# desc 'file IDENTIFIER...', 'Sync a file from the cache'
# def file(*identifiers)
#   FlightSyncer::SyncManifest.remote do |manifest|
#     identifiers.each do |identifier|
#       if (metafile = manifest.get_metafile(identifier)).nil?
#         $stderr.puts <<-WARN.strip_heredoc
#           Warning: Could not locate '#{identifier}' file in sync manifest
#         WARN
#       else
#         metafile.save_from_cache
#       end
#     end
#   end
# end

# class Group < Thor
#   # Only show the 'add' command if on the cache server (aka the public dir
#   # has been defined)

#   desc 'get GROUP', 'Sync all the files within the group'
#   def get(group)
#     FlightSyncer::SyncManifest.remote do |manifest|
#       manifest.metafiles_in_group(group).each do |metafile|
#         metafile.save_from_cache
#       end
#     end
#   end
# end
# desc 'group SUBCOMMAND ...ARGS', 'Manage syncing a group of files'
# subcommand 'group', Group

