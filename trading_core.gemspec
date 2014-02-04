# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trading_core/version'

Gem::Specification.new do |spec|
  spec.name          = "trading_core"
  spec.version       = TradingCore::VERSION
  spec.authors       = ["Chad Johnson"]
  spec.email         = ["chad.d.johnson@gmail.com"]
  spec.description   = %q{Core libraries for trading projects}
  spec.summary       = %q{Core libraries for trading projects}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'activerecord'
  spec.add_runtime_dependency 'protected_attributes'
  spec.add_runtime_dependency 'mysql2'
  spec.add_runtime_dependency 'em-websocket'
  spec.add_runtime_dependency 'eventmachine'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'oauth'
  spec.add_runtime_dependency 'simple_oauth'
  spec.add_runtime_dependency 'em-http-request'
end
