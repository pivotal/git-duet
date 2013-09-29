# vim:fileencoding=utf-8

require 'rubygems'
require 'bundler/setup'

require 'simplecov' unless RUBY_PLATFORM == 'java'

$stderr.puts <<EOWARNING
----------------------------------------------------------------------------
WARNING: These specs do a lot of process spawning, which is relatively slow.
----------------------------------------------------------------------------
EOWARNING
