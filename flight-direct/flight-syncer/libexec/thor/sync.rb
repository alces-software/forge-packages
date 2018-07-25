#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'

desc 'add file', 'Add a file to the local cache'
def add(path)
  content = File.read(path)
  FlightSyncer::MetaFile.build_from_file(path).save_to_cache(content)
end

desc 'file identifiers...', 'Sync a file from the cache'
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
