require 'pathname'
require 'sidekiq'

BASE = Pathname.new(__FILE__).realpath.parent.parent
$: << BASE # for config initializers
$: << BASE + 'lib'

require_relative 'colore'
require 'config/initializers/sidekiq.rb'
