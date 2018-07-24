
module FlightSyncer
  class SyncManifest
    class << self
      def path
        key = 'FL_CONFIG_PUBLIC_DIR'
        raise <<-ERROR.squish unless ENV[key]
          Can not locate the sync manifest, please set #{key}
        ERROR
        File.join(ENV[key], 'syncer-manifest.yaml')
      end
    end
  end
end

