#!/usr/bin/env ruby
#
# Simple sinatra app to receive and display callbacks
#
require 'pp'
require 'sinatra'

set :port, 9230

post '/callback' do
  puts "Received callback"
  pp params
end
