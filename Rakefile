#!/usr/bin/env rake
# vim:fileencoding=utf-8
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Rubocop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation'
end

task default: [:rubocop, :spec]
