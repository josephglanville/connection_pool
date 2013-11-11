# -*- encoding: utf-8 -*-
require "./lib/multithink/version"

Gem::Specification.new do |s|
  s.name        = "multithink"
  s.version     = MultiThink::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joseph Glanville"]
  s.email       = ["jpg@jpg.id.au"]
  s.homepage    = "https://github.com/josephglanville/multithink"
  s.description = s.summary = %q{Simple RethinkDB connection pool.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.license = "MIT"
  s.add_runtime_dependency 'rethinkdb', '>= 1.10.0'
  s.add_development_dependency 'minitest', '>= 5.0.0'
  s.add_development_dependency 'rake'
end
