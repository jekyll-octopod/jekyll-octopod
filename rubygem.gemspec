# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jekyll/podcasting/version"

Gem::Specification.new do |s|
  s.name = "podcasting"
  s.version = Jekyll::Podcasting::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.authors = ["Stefan Haslinger"]
  s.email = ["stefan.haslinger@informatom.com"]
  s.homepage = "https://github.com/haslinger/podcasting"
  s.summary = %q{Podcasting Publishing Extension for Jekyll}
  s.description = %q{Podcasting Publishing Extension for Jekyll}

  s.rubyforge_project = "podcasting"
  s.files = Dir["lib/**/*"] + ["README.rdoc"]
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_dependency 'some-gem', '>= 0.0'

  s.add_development_dependency 'rspec', '>= 2.9'
end
