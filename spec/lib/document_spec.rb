require 'spec_helper'
require 'document'
require 'doc_key'
require 'errors'

describe Colore::Document do
  let(:app) { 'app' }
  let(:doc_id) { '12345' }
  let(:doc_key) { Colore::DocKey.new(app,doc_id) }
  let(:invalid_doc_key) { Colore::DocKey.new(app,'bollox') }
  let(:storage_dir) { tmp_storage_dir }
  let(:document) { described_class.load storage_dir, doc_key }

  before do
    setup_storage
  end

  after do
    delete_storage
  end

  context '.directory' do
    it 'runs' do
      expect(described_class.directory(storage_dir,doc_key).to_s).to_not be_nil
    end
  end

  context '.version_directory' do
    it 'runs' do
      expect(described_class.version_directory(storage_dir,doc_key,:foo).to_s).to_not be_nil
    end
  end

  context '.version_path' do
    it 'runs' do
      expect(described_class.version_path(doc_key,:foo).to_s).to_not be_nil
    end
  end

  context '.exists?' do
    it 'runs' do
      expect(described_class.exists?(storage_dir,doc_key)).to eq true
    end

    it 'returns false if directory does not exist' do
      expect(described_class.exists?(storage_dir,invalid_doc_key)).to eq false
    end
  end

  context '.create' do
    it 'runs' do
      create_key = Colore::DocKey.new('app2','foo')
      doc = described_class.create storage_dir, create_key, 'This is a title'
      expect(doc).to_not be_nil
      expect(described_class.exists?(storage_dir, create_key)).to eq true
      expect(doc.title).to eq 'This is a title'
    end

    it 'raises error if doc already exists' do
      expect{
        described_class.create storage_dir, doc_key, 'Another title'
      }.to raise_error Colore::DocumentExists
    end
  end

  context '.load' do
    it 'runs' do
      doc = described_class.load storage_dir, doc_key
      expect(doc).to_not be_nil
      expect(doc.title).to eq 'Sample document'
      expect(doc.current_version).to eq 'v002'
      expect(doc.versions.size).to eq 2
      [ :v001, :v002 ].each do |version|
        expect(doc.versions[version]).to_not be_nil
        v  = doc.versions[version]
        expect(v.created_by).to_not be_nil
        expect(v.formats.size).to eq 2
        [ Colore::Format::ORIGINAL, :txt ].each do |format|
          expect(v.formats[format]).to_not be_nil
          f = v.formats[format]
          expect(f.content_type).to_not be_nil
          expect(f.filename).to_not be_nil
          expect(f.path).to_not be_nil
          expect(File.exists? storage_dir + f.path).to eq true
        end
      end
    end

    it 'raises exception if directory does not exist' do
      expect{
        described_class.load storage_dir, invalid_doc_key
      }.to raise_error Colore::DocumentNotFound
    end
  end

  context '.delete' do
    it 'runs' do
      Colore::Document.delete storage_dir, doc_key
      expect(Colore::Document.exists? storage_dir, doc_key).to eq false
    end
  end

  context '#directory' do
    it 'runs' do
      dir = document.directory
      expect(dir).to_not be_nil
      expect(File.exists? dir).to eq true
    end
  end

  context '#version_directory' do
    it 'runs' do
      dir = document.version_directory :v001
      expect(dir).to_not be_nil
      expect(File.exists? dir).to eq true
    end
  end

  context '#exists' do
    it 'runs' do
      expect(document.version_exists? :v001).to eq true
    end
    it 'returns false if version does not exist' do
      expect(document.version_exists? :foo).to eq false
    end
  end

  context '#title=' do
    it 'runs' do
      document.title = 'New title'
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.title).to eq 'New title'
    end

    it 'does not save a nil title' do
      document.title = nil
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.title).to eq 'Sample document'
    end
  end

  context '#new_version' do
    it 'runs' do
      version = document.new_version 'a.nother'
      expect(version).to_not be_nil
      expect(File.exists? document.version_directory(version)).to eq true
      expect(document.versions.include? version).to eq true
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.versions.include? version).to eq true
      expect(new_doc.versions[version].created_by).to eq 'a.nother'
    end
  end

  context '#add_file' do
    it 'runs' do
      body = File.read(__FILE__)
      format = 'ruby'
      document.add_file 'v002', format, File.basename(__FILE__), body, 'a.nother'
      f = document.versions[:v002].formats[format]
      expect(f).to_not be_nil
      expect(f.filename).to eq File.basename(__FILE__)
      expect(f.content_type).to eq "text/x-ruby; charset=us-ascii"
      expect(f.path).to eq( (Pathname.new(app)+doc_id+'v002'+f.filename))
    end
  end

  context '#set_current' do
    it 'runs' do
      document.set_current :v001
      expect(document.current_version).to eq :v001
      st1 = File.stat( document.directory + 'current' )
      st2 = File.stat( document.directory + 'v001' )
      expect(st1.ino).to eq st2.ino
    end

    it 'fails when you try an invalid version' do
      expect {
        document.set_current :v009
      }.to raise_error Colore::VersionNotFound
    end
  end

  context '#delete_version' do
    it 'runs' do
      document.delete_version :v001
      expect(document.version_exists? :v001).to eq false
      expect(document.versions.include? :v001).to eq false
    end
    it 'refuses to delete current version' do
      expect {
        document.delete_version :v002
      }.to raise_error Colore::VersionIsCurrent
    end
    it 'silently does nothing for an invalid version' do
      document.delete_version :foo
    end
  end

  context '#get_file' do
    it 'runs' do
      content_type, body = document.get_file :v001, 'original'
      expect(content_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
      expect(body).to_not be_nil
    end
    it 'runs for current' do
      content_type, body = document.get_file :current, 'converted.txt'
      expect(content_type).to eq 'text/plain; charset=us-ascii'
      expect(body).to_not be_nil
    end
    it 'raises FileNotFound for an invalid version' do
      expect {
        document.get_file :foo, 'converted.txt'
      }.to raise_error Colore::FileNotFound
    end
    it 'raises FileNotFound for an invalid filename' do
      expect {
        document.get_file :v001, 'text/plain; charset=us-ascii'
      }.to raise_error Colore::FileNotFound
    end
  end

  context '#to_hash' do
    it 'runs' do
      dochash = JSON.parse( File.read(fixture('document.json')) )
      dochash = Colore::Utils.symbolize_keys dochash
      expect(document.to_hash).to match dochash
    end
  end
end

describe Colore::Version do
  let(:app) { 'app' }
  let(:doc_id) { '12345' }
  let(:doc_key) { Colore::DocKey.new(app,doc_id) }
  let(:version_key) { :v001 }
  let(:version) { document.versions[version_key] }
  let(:invalid_doc_key) { Colore::DocKey.new(app,'bollox') }
  let(:storage_dir) { tmp_storage_dir }
  let(:document) { Colore::Document.load storage_dir, doc_key }

  before do
    setup_storage
  end

  after do
    delete_storage
  end

  context '.load' do
    it 'runs' do
      v = described_class.load(document.version_directory(version_key), Colore::Document.version_path(doc_key,version_key))
      expect(v).to be_a(Colore::Version)
      expect(v.directory).to eq document.version_directory(version_key)
      expect(v.version_path).to eq Colore::Document.version_path(doc_key,version_key)
      expect(v.created_by).to eq 'a.person'
      expect(v.formats.size).to eq 2
    end
  end

  context '#add_file' do
    it 'runs' do
      version.add_file 'ruby', File.basename(__FILE__), File.read(__FILE__)
      format = version.formats['ruby']
      expect(format).to_not be_nil
      expect(format.content_type).to eq 'text/x-ruby; charset=us-ascii'
      expect(format.filename).to eq File.basename(__FILE__)
      expect(format.path).to_not be_nil
    end
  end

  context '#to_hash' do
    it 'runs' do
      vhash = JSON.parse( File.read( fixture('version.json') ) )
      vhash = Colore::Utils.symbolize_keys vhash
      expect(version.to_hash).to eq vhash
    end
  end

  context '#save' do
    it 'runs' do
      version.created_by = 'a.nother'
      version.save
      v2 = described_class.load(document.version_directory(version_key), Colore::Document.version_path(doc_key,version_key))
      expect(v2.created_by).to eq 'a.nother'
    end
  end
end

describe Colore::Format do
  let(:format) {
    described_class.new content_type: 'foo', filename: 'bar', path: 'fred'
  }
  context '#to_hash' do
    it 'runs' do
      expect(format.to_hash).to match({
        content_type: 'foo',
        filename: 'bar',
        path: 'fred'
      })
    end
  end
end
