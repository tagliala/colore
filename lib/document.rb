require 'json'
require 'filemagic/ext'
require_relative 'doc_key'

module Colore
  class Document
    attr_reader :base_dir
    attr_reader :doc_key
    attr_reader :title
    attr_reader :current_version
    attr_reader :versions

    def self.directory base_dir, doc_key
      base_dir + doc_key.path
    end

    def self.version_directory base_dir, doc_key, version
      directory(base_dir,doc_key) + version.to_s
    end

    def self.version_path doc_key, version
      doc_key.path + version.to_s
    end

    def self.exists? base_dir, doc_key
      File.exist? directory(base_dir, doc_key)
    end

    def self.create base_dir, doc_key, title=nil
      doc_dir = directory base_dir, doc_key
      raise DocumentExists.new if File.exist? doc_dir
      FileUtils.mkdir_p doc_dir
      metadata = Utils.read_metadata doc_dir
      doc = Document.new base_dir, doc_key, metadata
      doc.title= title # side-effect: saves
      doc
    end

    def self.load base_dir, doc_key
      raise DocumentNotFound.new unless exists? base_dir, doc_key
      metadata = Utils.read_metadata directory(base_dir, doc_key)
      doc = new base_dir, doc_key, metadata
      metadata[:versions].each do |version|
        doc.versions[version.to_sym] = Version.load(
          version_directory(base_dir, doc_key, version),
          version_path( doc_key, version )
        )
      end
      doc
    end

    def self.delete base_dir, doc_key
      return unless exists? base_dir, doc_key
      FileUtils.rm_rf directory( base_dir, doc_key )
    end

    def initialize base_dir, doc_key, metadata={}
      @base_dir = base_dir
      @doc_key = doc_key

      @title = metadata[:title]
      @current_version = metadata[:current_version]
      @versions = {}
    end

    def directory
      self.class.directory @base_dir, @doc_key
    end

    def version_directory version
      self.class.version_directory @base_dir, @doc_key, version
    end

    def version_exists? version
      File.exist? version_directory(version)
    end

    def title= new_title
      return unless new_title
      @title = new_title
      save
    end

    def new_version created_by=nil
      v_no = 0
      v_no = @current_version.gsub(/[^0-9]+/,'').to_i if @current_version
      new_dir = new_version = nil
      loop do
        v_no += 1
        new_version = "v%03d"%[v_no]
        new_dir = version_directory new_version
        break if ! File.exist? new_dir
      end
      Dir.mkdir new_dir
      @versions[new_version.to_sym] = Version.new(
        directory: new_dir,
        version_path: self.class.version_path(@doc_key,new_version),
        created_by: created_by
      )
      @versions[new_version.to_sym].save
      save
      new_version.to_sym
    end

    def add_file version_key, format, filename, body, created_by=nil
      key = version_key.to_sym
      raise VersionNotFound.new unless @versions[key]
      version = @versions[key]
      version.add_file format, filename, body
    end

    def set_current version_key
      key = version_key.to_sym
      raise VersionNotFound.new unless @versions[key]
      @current_version = key
      if version_exists? 'current'
        # need to do this, or ln_s will put the symlink *into* the old dir
        File.unlink directory + 'current'
      end
      FileUtils.ln_s version_directory(key), version_directory('current'), force: true
      save
    end

    def delete_version version_key
      key = version_key.to_sym
      raise VersionIsCurrent.new if key.to_sym == :current
      return unless @versions[key]
      raise VersionIsCurrent.new if @current_version.to_sym == key.to_sym
      FileUtils.rm_rf version_directory(key)
      @versions.delete key
      save
    end

    def get_file version, filename
      path = version_directory(version) + filename
      raise FileNotFound unless File.exist? path
      body = File.read path
      return body.mime_type, body
    end

    def to_hash
      h = {
        app: @doc_key.app,
        doc_id: @doc_key.doc_id,
        current_version: @current_version,
        versions: {}
      }
      @versions.each { |k,v| h[:versions][k] = v.to_hash }
      h
    end

    protected

    def metadata_filename
      directory + 'metadata.json'
    end

    def load_metadata
      metadata = {}
    end

    def save
      metadata = {
        app: @doc_key.app,
        doc_id: @doc_key.doc_id,
        title: @title,
        current_version: @current_version,
        versions: @versions.keys,
      }
      File.open( directory + 'metadata.json', "w" ) { |f| f.puts metadata.to_json }
    end
  end

  class Version
    attr_reader :directory
    attr_reader :version_path
    attr_accessor :created_by
    attr_reader :formats

    def self.load directory, version_path
      md = Utils.read_metadata directory
      self.new( {directory: directory, version_path: version_path}.merge(md) )
    end

    def initialize metadata={}
      @directory = metadata[:directory]
      @version_path = metadata[:version_path]
      @created_by = metadata[:created_by]
      @formats = {}
      if metadata[:formats]
        metadata[:formats].each do |k,v|
          @formats[k] = Format.new(v)
        end
      end
    end

    def add_file format, filename, body
      format = (@formats[format] ||= Format.new)
      format.filename = filename
      format.path = @version_path + filename
      target = directory + filename
      case body
        when NilClass
          raise "Some bastard sent me a nil file"
        when Pathname # path name
          FileUtils.copy_file body.to_s, target
        when IO
          File.open( target, "wb" ) { |f| f.write body.read }
        else
          File.open( target, "wb" ) { |f| f.write body }
      end
      format.content_type = File.read(target,500).mime_type
      save
    end

    def to_hash
      h = {
         created_by: @created_by,
         formats: {}
      }
      @formats.each { |k,v| h[:formats][k] = v.to_hash }
      h
    end

    def save
      File.open( Utils.metadata_filename(@directory), "w" ) { |f| f.puts to_hash.to_json }
    end
  end

  class Format
    attr_accessor :content_type
    attr_accessor :filename
    attr_accessor :path

    ORIGINAL = :original

    def initialize metadata={}
      @content_type = metadata[:content_type]
      @filename = metadata[:filename]
      @path = metadata[:path]
    end

    def to_hash
      {
        content_type: @content_type,
        filename: @filename,
        path: @path,
      }
    end
  end
end
