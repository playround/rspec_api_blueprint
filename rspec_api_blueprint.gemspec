# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec_api_blueprint/version'

Gem::Specification.new do |spec|
  spec.name          = "rspec_api_blueprint"
  spec.version       = RspecApiBlueprint::VERSION
  spec.authors       = ["Matteo Depalo"]
  spec.email         = ["matteodepalo@gmail.com"]
  spec.description   = %q{Autogeneration of documentation from request specs}
  spec.summary       = %q{Autogeneration of documentation from request specs}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'rspec-rails'
  spec.add_dependency 'activesupport'
end
