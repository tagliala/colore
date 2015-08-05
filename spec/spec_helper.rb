require 'pathname'
require 'fileutils'
require 'logger'
require 'byebug'
require 'rack/test'
require 'simplecov'
require 'timecop'

SimpleCov.start

SPEC_BASE = Pathname.new(__FILE__).realpath.parent

$: << SPEC_BASE.parent + 'lib'
require 'colore'

def fixture name
  SPEC_BASE + 'fixtures' + name
end

def spec_logger
  Logger.new(nil)
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

require 'sidekiq/testing'
Sidekiq::Logging.logger = nil
