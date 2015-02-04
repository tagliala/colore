require 'pathname'
require 'json'
require 'filemagic/ext'
require_relative 'doc_key'

module Colore
  class Document
    attr_reader :base_dir
    attr_reader :doc_key

    CURRENT = 'current'

    def self.directory base_dir, doc_key
      Pathname.new(base_dir) + doc_key.path
    end

    def self.exists? base_dir, doc_key
      File.exist? directory(base_dir, doc_key)
    end

    def self.create base_dir, doc_key
      doc_dir = directory base_dir, doc_key
      raise DocumentExists.new if File.exist? doc_dir
      FileUtils.mkdir_p doc_dir
      self.new base_dir, doc_key
    end

    def self.load base_dir, doc_key
      raise DocumentNotFound.new unless exists? base_dir, doc_key
      doc = self.new base_dir, doc_key
    end

    def self.delete base_dir, doc_key
      return unless exists? base_dir, doc_key
      FileUtils.rm_rf directory( base_dir, doc_key )
    end

    def initialize base_dir, doc_key
      @base_dir = base_dir
      @doc_key = doc_key
    end

    def directory
      self.class.directory @base_dir, @doc_key
    end

    def title
      return '' unless File.exist?( directory + 'title' )
      File.read( directory + 'title' ).chomp
    end

    def title= new_title
      return if new_title.to_s.empty?
      File.open( directory + 'title', 'w' ) { |f| f.puts new_title  }
    end

    def versions
      versions = Dir.glob( directory + 'v*' )
      versions.reject { |v| ! v =~ /^v\d+$/ }.map{ |v| File.basename v }.sort
    end

    def has_version? version
      versions.include?(version) || version == CURRENT
    end

    def current_version
      (directory + CURRENT).realpath.basename.to_s
    end

    def next_version_number
      v_no = (versions.last || 'v000').gsub(/v/,'').to_i + 1
      "v%03d"%[v_no]
    end

    def new_version
      nvn = next_version_number
      Dir.mkdir directory + nvn
      nvn
    end

    def add_file version, filename, body
      raise VersionNotFound.new unless File.exist?( directory + version )
      File.open( directory + version + filename, "wb" ) { |f| f.write body }
    end

    def set_current version
      raise VersionNotFound.new unless File.exist?( directory + version )
      raise InvalidVersion.new unless version =~ /^v\d+$/
      # need to do this, or ln_s will put the symlink *into* the old dir
      File.unlink directory + CURRENT if File.exist? directory + CURRENT
      FileUtils.ln_s (directory + version).realpath, directory + CURRENT, force: true
    end

    def delete_version version
      return unless File.exist?( directory + version )
      raise VersionIsCurrent.new if version == CURRENT
      raise VersionIsCurrent.new if (directory + CURRENT).realpath == (directory+version).realpath
      FileUtils.rm_rf( directory + version )
    end

    def get_file version, filename
      path = directory + version + filename
      raise FileNotFound unless File.exist? path
      body = File.read path
      return body.mime_type, body
    end

    def to_hash
      v_list = {}
      versions.each do |v|
        v_list[v] = {}
        Dir.glob(directory + v + '*').each do |file|
          content_type = File.read(file,200).mime_type
          suffix = File.extname(file).gsub( /\./, '')
          next if suffix.empty?
          v_list[v][suffix] = {
            content_type: content_type,
            filename: File.basename(file),
            path: file.to_s[directory.to_s.length..-1],
          }
        end
      end
      {
        app: @doc_key.app,
        doc_id: @doc_key.doc_id,
        title: title,
        current_version: current_version,
        versions: v_list,
      }
    end

    def save_metadata
      File.open( directory + 'metadata.json', "w" ) do |f|
        f.puts JSON.pretty_generate(to_hash)
      end
    end
  end

end
