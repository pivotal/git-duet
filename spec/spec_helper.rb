require 'rubygems'
require 'bundler/setup'

require 'rbconfig'

unless RUBY_PLATFORM == 'java'
  require 'simplecov'
end

RSpec.configure do |c|
  if !ENV['TRAVIS']
    if RbConfig::CONFIG['host_os'] =~ /darwin/i
      c.formatter = 'NyanCatMusicFormatter'
    else
      # No music allowed for neckbeards or polo shirts.
      c.formatter = 'NyanCatFormatter'
    end
  end
end

$stderr.puts <<EOWARNING
----------------------------------------------------------------------------
WARNING: These specs do a lot of process spawning, which is relatively slow.
----------------------------------------------------------------------------
EOWARNING
