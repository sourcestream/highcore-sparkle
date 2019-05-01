$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'

Gem::Specification.new do |s|
  s.name               = "highcore_sparkle"
  s.version            = "0.0.7"

  s.authors = ["Aleksandr Saraikin"]
  s.date = %q{2015-11-14}
  s.description = %q{Highcore adapter for sparkle formation}
  s.email = %q{alex@sourcestream.de}
  s.files = Dir['{lib}/**/*'] + %w(highcore_sparkle.gemspec LICENSE.md)
  s.test_files = Dir['{spec}/**/*']
  s.homepage = %q{http://rubygems.org/gems/highcore_sparkle}
  s.license = 'MIT'
  s.require_path = 'lib'
  s.summary = %q{Highcore adapter for sparkle formation}
  s.add_dependency('sparkle_formation', '=3.0.38')

end

