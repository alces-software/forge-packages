#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'

desc 'add FILE', 'Add a file to the local cache'
METAFILE_PARAMS = {
  path: 'The sync path of the file',
  identifier: 'A unique refernce to the file, defaults to the basename',
  mode: 'Sets the file permissions as an octal',
  owner: 'Sets the files owner',
  group: 'Sets the files group'
}.each do |key, option_desc|
  method_option key, desc: option_desc
end
def add(path)
  content = File.read(path)
  params = options.symbolize_keys.select do |k, _v|
    METAFILE_PARAMS.keys.include?(k)
  end
  FlightSyncer::MetaFile.build_from_file(path, **params)
                        .save_to_cache(content)
end

desc 'file IDENTIFIER...', 'Sync a file from the cache'
def file(*identifiers)
  FlightSyncer::SyncManifest.remote do |manifest|
    identifiers.each do |identifier|
      if (metafile = manifest.get_metafile(identifier)).nil?
        $stderr.puts <<-WARN.strip_heredoc
          Warning: Could not locate '#{identifier}' file in sync manifest
        WARN
      else
        metafile.save_from_cache
      end
    end
  end
end
