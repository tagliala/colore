require 'pathname'
require "sinatra"

BASE=Pathname.new(__FILE__).realpath.parent
$: << BASE + 'lib'
require 'app'

run Colore::App
