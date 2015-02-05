require 'filemagic/ext'
require 'pathname'
HEATHEN_BASE = Pathname.new(__FILE__).realpath.parent + 'heathen'

require_relative 'heathen/errors'
require_relative 'heathen/filename'
require_relative 'heathen/job'
require_relative 'heathen/task'
require_relative 'heathen/converter'
require_relative 'heathen/executioner'
require_relative 'heathen/processor'
Dir.glob( (HEATHEN_BASE+'processor_methods'+'*.rb').to_s ).each do |method|
  require_relative method
end
