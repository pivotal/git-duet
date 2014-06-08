# vim:fileencoding=utf-8
require File.expand_path('../lib/git/duet/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = [
    'Dan Buch',
    'Jesse Szwedko',
    'Rafe Colton',
    'Sheena McCoy'
  ]
  gem.email = %w(
    d.buch@modcloth.com
    j.szwedko@modcloth.com
    r.colton@modcloth.com
    sp.mccoy@modcloth.com
  )
  gem.description = %q(Pair programming git identity thingy)
  gem.summary = "Pair harmoniously!  Decide who's driving.  " \
                "Commit along the way.  Don't make a mess of " \
                'the repository history.'
  gem.homepage = 'https://github.com/modcloth/git-duet'
  gem.license = 'MIT'

  gem.files = `git ls-files -z`.split("\x00")
  gem.executables = gem.files.grep(/^bin\//)
                             .map { |f| File.basename(f) }
                             .reject { |n| n =~ /rubymine-git-wrapper/ }
  gem.test_files = gem.files.grep(/^spec\//)
  gem.name = 'git-duet'
  gem.require_paths = %w(lib)
  gem.version = Git::Duet::VERSION
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubocop'

  gem.add_development_dependency 'posix-spawn' unless RUBY_PLATFORM == 'java'
  gem.add_development_dependency 'pry' unless RUBY_PLATFORM == 'java'
  gem.add_development_dependency 'simplecov' unless RUBY_PLATFORM == 'java'
end
