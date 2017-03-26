# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deadman_check/version'

Gem::Specification.new do |spec|
  spec.name          = "deadman_check"
  spec.version       = DeadmanCheck::VERSION
  spec.authors       = ["zane"]
  spec.email         = ["zane.williamson@gmail.com"]

  spec.summary       = %q{Monitor a Consul key that contains an EPOCH time entry.
    Send email if EPOCH age hits given threshold}
  spec.description   = %q{A script to check a given Consul key EPOCH for
    freshness. Good for monitoring cron jobs or batch jobs. Have the last step
    of the job post the EPOCH time to target Consul key. This script will monitor
    it for a given freshness value (difference in time now to posted EPOCH)}
  spec.homepage      = "https://github.com/sepulworld/deadman-check"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
    spec.metadata['optional_gems']     = "keyring"
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = "deadman-check"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency 'commander', '~> 4.4', '>= 4.4.3'
  spec.add_dependency 'diplomat', '~> 1.2', '>= 1.2.0'
  spec.add_dependency 'slack-ruby-client', '~> 0.8.0'
  spec.add_dependency 'daemons', '~> 1.2.4', '>=1.2.4'
end
