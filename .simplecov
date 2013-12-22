# vim:filetype=ruby:fileencoding=utf-8
SimpleCov.command_name 'test:all'
SimpleCov.start { add_filter '/spec/' } if ENV['COVERAGE']
SimpleCov.use_merging true
