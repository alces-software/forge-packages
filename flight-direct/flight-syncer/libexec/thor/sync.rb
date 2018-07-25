#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'

desc 'add file', 'Add a file to the local cache'
def add(path)
  content = File.read(path)
  FlightSyncer::MetaFile.build_from_file(path).save_to_cache(content)
end

desc 'file identifier', 'Sync a file from the cache'
def file(identifier)
  FlightSyncer::SyncManifest.remote do |manifest|
    binding.pry
  end
end
