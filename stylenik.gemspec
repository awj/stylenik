$:.push File.expand_path("../lib", __FILE__)
require "stylenik/version"

Gem::Specification.new do |s|
  s.name        = "stylenik"
  s.version     = Stylenik::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Jones"]
  s.email       = ["ajones1@gmail.com"]
  s.homepage    = "http://github.com/awj/stylenik"
  s.summary     = "Programmatic style creation for mapnik"
  s.description = "Programmatic style creation for mapnik"

  s.rubyforge_project = "stylenik"

  s.files         = `git ls-files`.split("\n")
#   s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
#   s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency "nokogiri"
end
