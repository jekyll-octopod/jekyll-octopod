# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "octopod/version"

Gem::Specification.new do |s|
  s.name = "jekyll-octopod"
  s.version = Jekyll::Octopod::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.authors = ["Arne Eilermann", "Stefan Haslinger"]
  s.email = ["stefan.haslinger@informatom.com"]
  s.homepage = "https://github.com/haslinger/jekyll-octopod"
  s.summary = %q{Podcasting Publishing Extension for Jekyll}
  s.description = %q{Enables you to publish your podcast using the Jekyll static site generator, creating feeds and a reasonably looking website}
  s.license = "MIT"

  s.rubyforge_project = "jekyll-"
  s.files = Dir["lib/**/*"] + ["Rakefile", "README.md"] + Dir["assets/**/*"]
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'facets', '~> 3.1'
  s.add_dependency 'jekyll', '~> 4.0'
  s.add_dependency 'jekyll-bootflat', '~> 0.3.2'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_dependency 'jekyll-admin', '~> 0.10'
  s.add_dependency 'kramdown-parser-gfm', '~> 1.1'
end
