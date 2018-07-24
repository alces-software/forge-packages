#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'

desc 'add file', 'Add a file to the local cache'
def add(path)
  FlightSyncer::CacheFile.build_from_file(path).save_to_cache
end
