require 'pathname'
require 'fileutils'
require 'byebug'
require 'rack/test'
$: << Pathname.new(__FILE__).realpath.parent.parent + 'lib'

def fixture name
  Pathname.new(__FILE__).realpath.parent + 'fixtures' + name
end

def tmp_storage_dir
  Pathname.new('/tmp') + "colore_test.#{Process.pid}"
end

def setup_storage
  FileUtils.rm_rf tmp_storage_dir
  FileUtils.mkdir_p tmp_storage_dir
  FileUtils.cp_r fixture('app'), tmp_storage_dir
end

def delete_storage
  FileUtils.rm_rf tmp_storage_dir
end

module RSpecMixin
  include Rack::Test::Methods
  def app() described_class end
end

ENV['RACK_ENV'] = 'test'

RSpec::configure do |rspec|
  rspec.tty = true
  rspec.color = true
  rspec.include RSpecMixin
end

