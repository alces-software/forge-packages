
require 'active_model'
require 'etc'
require 'flight_syncer/sync_manifest'

module FlightSyncer
  class MetaFile
    include ActiveModel

    class << self
      def build_from_file(path, **options)
        new(**options).tap do |x|
          File.open(path) do |file|
            x.path ||= path
            x.identifier ||= File.basename(x.path, '.*')
            x.mode ||= file.stat.mode.to_s(8)
            x.owner ||= Etc.getpwuid(file.stat.uid).name
            x.group ||= Etc.getgrgid(file.stat.gid).name
          end
        end
      end

      def build_from_hash(hash)
        new.tap do |x|
          hash.each { |key, value| x.public_send("#{key}=", value) }
        end
      end
    end

    def initialize(**parameters)
      parameters.each { |key, value| public_send("#{key}=", value) }
    end

    HASH_ACCESSOR = [:identifier, :path, :mode, :owner, :group]
    attr_accessor(*HASH_ACCESSOR)

    def to_h
      HASH_ACCESSOR.map { |key| [key, public_send(key)] }.to_h
    end

    def relative_identifier_path
      File.join('syncer', identifier.to_s)
    end

    def save_to_cache(content)
      SyncManifest.new.tap do |manifest|
        manifest.add_file(self, content)
      end.save
    end

    def save_from_cache
      io = URI.parse(url).open
      FileUtils.mkdir_p File.dirname(sync_path)
      File.open(sync_path, 'w') do |file|
        begin
          file.chown(uid, gid)
          file.chmod(mode.to_i(8))
          file.write(io.read)
        rescue => e
          FileUtils.rm_f file.path
          raise e
        end
      end
    end

    private

    # The sync_path is not guaranteed to always be the same as the path
    # (due to system configuration). The `path` method denotes
    # what is saved into the SyncManifest only. `sync_code` however will
    # contain more advanced features TBA
    alias_method :sync_path, :path

    def url
      cache_url = FlightConfig.get('cache-url', allow_missing: false)
      File.join(cache_url, relative_identifier_path)
    end

    def uid
      Etc.getpwnam(owner).uid
    end

    def gid
      Etc.getgrnam(group).gid
    end
  end
end
