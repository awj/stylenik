$:.push File.expand_path("../lib", __FILE__)
require "stylenik/version"

Gem::Specification.new do |s|
  s.name        = "stylenik"
  s.version     = Stylenik::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Jones"]
  s.email       = ["ajones1@gmail.com"]
  s.homepage    = "http://github.com/awj/stylenik"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "stylenik"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
