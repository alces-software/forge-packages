#: SYNOPSIS: Sync files from the cache

require 'flight_syncer'

desc 'add file', 'Add a file to the local cache'
def add(path)
  content = File.read(path)
  FlightSyncer::MetaFile.build_from_file(path).save_to_cache(content)
end
