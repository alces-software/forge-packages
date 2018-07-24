
require 'yaml'

module FlightSyncer
  class SyncManifest
    class << self
      def path
        File.join(public_dir, 'syncer-manifest.yaml')
      end

      def read
        return {} unless File.exists? path
        (YAML.load_file(path) || {}).deep_symbolize_keys
      end

      def public_dir
        key = 'FL_CONFIG_PUBLIC_DIR'
        raise <<-ERROR.squish unless ENV[key]
          Can not locate the sync manifest, please set #{key}
        ERROR
        ENV[key]
      end
    end

    def data
      @data ||= self.class.read
    end

    def add_file(file_model, content)
      identifier = file_model.identifier.to_sym
      raise <<-ERROR.squish if get_file(identifier)
        A file has already been cached with the identifier: #{identifier}
      ERROR
      new_files_content_cache[identifier] = content
      data[:files][identifier] = file_model.to_h
    end

    def get_file(identifier)
      raw = (data[:files] ||= {})[identifier.to_sym]
      return if raw.nil? || raw.empty?
      MetaFile.build_from_hash(raw)
    end

    def save
      new_files_content_cache.each do |identifier, content|
        path = File.join(self.class.public_dir, relative_identifier_path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end
      File.write(self.class.path, YAML.dump(data.deep_stringify_keys))
    end

    private

    def new_files_content_cache
      @new_file_content_cache ||= {}
    end
  end
end

