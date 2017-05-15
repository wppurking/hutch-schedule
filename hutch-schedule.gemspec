# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hutch/schedule/version'

Gem::Specification.new do |spec|
  spec.name    = "hutch-schedule"
  spec.version = Hutch::Schedule::VERSION
  spec.authors = ["wyatt pan"]
  spec.email   = ["wppurking@gmail.com"]

  spec.summary     = %q{Add Schedule and Error Retry To Hutch.}
  spec.description = %q{Add Schedule and Error Retry To Hutch.}
  spec.homepage    = "https://github.com/wppurking/hutch-schedule"
  spec.license     = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'hutch', '~> 0.24'

  spec.add_development_dependency "activejob"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.8"
end
