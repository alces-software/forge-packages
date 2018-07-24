
require 'yaml'

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

      def read
        return {} unless File.exists? path
        (YAML.load_file(path) || {}).deep_symbolize_keys
      end
    end

    def data
      @data ||= self.class.read
    end

    def add_file(file_model)
      identifier = file_model.identifier.to_sym
      raise <<-ERROR.squish if get_file(identifier)
        A file has already been cached with the identifier: #{identifier}
      ERROR
      data[:files][identifier] = file_model.to_h
    end

    def get_file(identifier)
      (data[:files] ||= {})[identifier.to_sym]
    end

    def save
      File.write(self.class.path, YAML.dump(data.deep_stringify_keys))
    end
  end
end

