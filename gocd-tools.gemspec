# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gocdtools/version'

Gem::Specification.new do |spec|
  spec.name          = "gocd-tools"
  spec.version       = GocdTools::VERSION
  spec.authors       = ["Sebastian Thiel"]
  spec.email         = ["byronimo@gmail.com"]

  spec.summary       = %q{Utilities to help operating a gocd instance}
  spec.description   = %q{Clean cruise-config.xml files and encrypt secrets}
  spec.homepage      = "https://github.com/byron/gocd-tools"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
