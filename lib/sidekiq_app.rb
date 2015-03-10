#
# Application initializer for the Colore Sidekiq process. See (BASE/run_sidekiq) for usage.
#
#
require 'pathname'
require 'sidekiq'

BASE = Pathname.new(__FILE__).realpath.parent.parent
$: << BASE # for config initializers
$: << BASE + 'lib'

require 'config/initializers/sidekiq.rb'

require_relative 'colore'
