require 'pathname'
require 'fileutils'
require 'logger'
require 'byebug'
require 'rack/test'


SPEC_BASE = Pathname.new(__FILE__).realpath.parent

$: << SPEC_BASE.parent + 'lib'
require 'heathen'

def fixture name
  SPEC_BASE + 'fixtures' + name
end

Dir.glob( (SPEC_BASE+"helpers"+"**.rb").to_s ).each do |helper|
  require helper
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

