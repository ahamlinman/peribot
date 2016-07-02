# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'peribot/version'

Gem::Specification.new do |spec|
  spec.name          = 'peribot'
  spec.version       = Peribot::VERSION
  spec.authors       = ['Alex Hamlin']
  spec.email         = ['alex@alexhamlin.co']

  spec.summary       = 'Flexible, asynchronous chatbot framework for GroupMe'
  spec.homepage      = 'https://github.com/ahamlinman/peribot'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.2'

  spec.add_dependency 'concurrent-ruby', '~> 1.0.1'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 11.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.39.0'
  spec.add_development_dependency 'simplecov', '~> 0.11.2'
  spec.add_development_dependency 'timecop', '~> 0.8.0'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8.8'
end
