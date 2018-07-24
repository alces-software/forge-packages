
require 'active_model'
require 'etc'
require 'flight_syncer/sync_manifest'

module FlightSyncer
  class CacheFile
    include ActiveModel

    class << self
      def build_from_file(path)
        new.tap do |x|
          File.open(path) do |file|
            x.identifier = File.basename(path, '.*')
            x.content = File.read(path)
            x.path = path
            x.mode = file.stat.mode.to_s(8)
            x.owner = Etc.getpwuid(file.stat.uid).name
            x.group = Etc.getgrgid(file.stat.gid).name
          end
        end
      end

      def build_from_hash(hash)
        new.tap do |x|
          hash.each { |key, value| x.public_send("#{key}=", value) }
        end
      end
    end

    HASH_ACCESSOR = [:identifier, :path, :mode, :owner, :group]
    attr_accessor(:content, *HASH_ACCESSOR)

    def to_h
      HASH_ACCESSOR.map { |key| [key, public_send(key)] }.to_h
    end

    def save_to_cache
      SyncManifest.new.tap { |cache| cache.add_file(self) }.save
    end
  end
end
