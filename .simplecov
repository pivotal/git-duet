# vim:fileencoding=utf-8
if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
  end
end
