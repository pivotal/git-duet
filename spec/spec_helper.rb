# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

unless RUBY_PLATFORM == 'java'
  require 'simplecov'
end

$stderr.puts <<EOWARNING
----------------------------------------------------------------------------
WARNING: These specs do a lot of process spawning, which is relatively slow.
----------------------------------------------------------------------------
EOWARNING
