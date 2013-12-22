# vim:filetype=ruby:fileencoding=utf-8
SimpleCov.command_name 'test:all' unless ENV['GIT_DUET_SIMPLECOV_RUNTIME']
SimpleCov.command_name 'runtime' if ENV['GIT_DUET_SIMPLECOV_RUNTIME']
SimpleCov.start { add_filter '/spec/' } if ENV['COVERAGE']
SimpleCov.use_merging true
