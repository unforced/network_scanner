# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'network_scanner/version'

Gem::Specification.new do |spec|
  spec.name          = "network_scanner"
  spec.version       = NetworkScanner::VERSION
  spec.authors       = ["Aaron Neyer"]
  spec.email         = ["aaronneyer@gmail.com"]
  spec.description   = %q{Various Network Scanning Utilities}
  spec.summary       = %q{Scans a network for machines that are up and ports that are open}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency 'thread'
end
