
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
        FlightConfig.get('public-dir', allow_missing: false)
      end
    end

    def new(path: nil)
      @manifest_path = path || self.class.path
    end

    def data
      @data ||= self.class.read
    end

    def add_file(metafile, content)
      identifier = metafile.identifier.to_sym
      raise <<-ERROR.squish if get_file(identifier)
        A file has already been cached with the identifier: #{identifier}
      ERROR
      new_files_content_cache[metafile] = content
      data[:files][identifier] = metafile.to_h
    end

    def get_file(identifier)
      raw = (data[:files] ||= {})[identifier.to_sym]
      return if raw.nil? || raw.empty?
      MetaFile.build_from_hash(raw)
    end

    def save
      new_files_content_cache.each do |metafile, content|
        path = File.join(self.class.public_dir,
                         metafile.relative_identifier_path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end
      File.write(manifest_path, YAML.dump(data.deep_stringify_keys))
    end

    private

    attr_reader :manifest_path

    def new_files_content_cache
      @new_file_content_cache ||= {}
    end
  end
end

