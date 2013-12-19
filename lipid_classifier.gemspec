$:.push File.expand_path("../lib", __FILE__)
require "lipid_classifier/version"

Gem::Specification.new do |s|
  s.name        = "lipid_classifier"
  s.version     = LipidClassifier::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan Taylor", "Ryan H. Miller"]
  s.email       = ["ryanmt@byu.net"]
  s.homepage    = "http://princelab.github.io/lipid_classifier"
  s.summary     = %q{Lipid Classification tool, a precursor to machine learning tools which specify rules of fragmentation and classify the code}
  s.description = %q{A work in progress, right now, we build upon SMART strings to match molecules or parts of molecules.}

  s.add_development_dependency "rspec", "~>2.5.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
