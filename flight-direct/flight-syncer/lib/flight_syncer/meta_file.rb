
require 'active_model'
require 'etc'
require 'flight_syncer/sync_manifest'

module FlightSyncer
  class MetaFile
    include ActiveModel

    class << self
      def build_from_file(path)
        new.tap do |x|
          File.open(path) do |file|
            x.identifier = File.basename(path, '.*')
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
    attr_accessor(*HASH_ACCESSOR)

    def to_h
      HASH_ACCESSOR.map { |key| [key, public_send(key)] }.to_h
    end

    def relative_identifier_path
      File.join('syncer', identifier.to_s)
    end

    def url
      key = 'FL_CONFIG_CACHE_URL'
      raise <<-ERROR.squish unless ENV[key]
        Can not determine the file location, please set: #{key}
      ERROR
      File.join(ENV[key], relative_identifier_path)
    end

    def save_to_cache(content)
      SyncManifest.new.tap do |manifest|
        manifest.add_file(self, content)
      end.save
    end
  end
end
