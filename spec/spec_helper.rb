require 'rubygems'
require 'bundler/setup'

require 'rbconfig'
require 'simplecov'
require 'pry'

RSpec.configure do |c|
  # No music allowed for neckbeards or polo shirts.
  if RbConfig::CONFIG['host_os'] =~ /darwin/i
    c.formatter = 'NyanCatMusicFormatter'
  else
    c.formatter = 'NyanCatFormatter'
  end
end
