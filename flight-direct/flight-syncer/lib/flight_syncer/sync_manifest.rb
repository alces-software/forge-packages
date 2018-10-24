
require 'yaml'
require 'open-uri'
require 'fileutils'
require 'tempfile'

module FlightSyncer
  class SyncManifest
    class << self
      def path
        File.join(public_dir, file_name)
      end

      def public_dir
        FlightConfig.get('public-dir', allow_missing: false)
      end

      def remote
        file = Tempfile.open(file_name)
        cache_url = FlightConfig.get('cache-url', allow_missing: false)
        io = URI.parse(File.join(cache_url, file_name)).open
        file.write(io.read)
        file.flush
        yield new(path: file.path) if block_given?
      ensure
        file.close
        file.unlink
      end

      def update
        new.tap { |x| yield x }.save
      end

      private

      def file_name
        'syncer-manifest.yaml'
      end
    end

    def initialize(path: nil)
      @manifest_path = path || self.class.path
    end

    def data
      @data ||= read
    end

    def add_file(metafile, content)
      identifier = metafile.identifier.to_sym
      raise <<-ERROR.squish if get_metafile(identifier)
        A file has already been cached with the identifier: #{identifier}
      ERROR
      new_files_content_cache[metafile] = content
      data[:files][identifier] = metafile.to_h
    end

    def add_files_to_group(group, *files)
      valid_files = files.select do |file|
        next true if get_metafile(file)
        $stderr.puts <<-WARN.squish
          WARNING: '#{file}' has not been cached, skipping adding it to the
          group
        WARN
        false
      end
      files_union = files_in_group(group) | valid_files
      (data[:groups] ||= {})[group.to_sym] = files_union
    end

    def files_in_group(group)
      Array.wrap((data[:groups] || {})[group.to_sym])
    end

    def get_metafile(identifier)
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

    def read
      return {} unless File.exists? manifest_path
      (YAML.load_file(manifest_path) || {}).deep_symbolize_keys
    end
  end
end

