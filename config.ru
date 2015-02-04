#\ -w -p 9240
require 'pathname'
require "sinatra"

BASE=Pathname.new(__FILE__).realpath.parent
$: << BASE
$: << BASE + 'lib'
require 'app'
require 'config/initializers/sidekiq'

run Colore::App
