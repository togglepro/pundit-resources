# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pundit/resources/version'

Gem::Specification.new do |spec|
  spec.name          = "pundit-resources"
  spec.version       = Pundit::Resources::VERSION
  spec.authors       = ["Ross Penman", "Sean Devine"]
  spec.email         = ["ross@pen.mn", "barelyknown@icloud.com"]

  spec.summary       = %q{Integrate JSONAPI::Resources with Pundit}
  spec.homepage      = "https://github.com/togglepro/pundit-resources"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "jsonapi-resources"
  spec.add_dependency "pundit"
  spec.add_dependency "rails", ">= 4.2.1", "< 5.2"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec-rails", '>= 3.5.0.beta3', '< 4.0.0'
end
