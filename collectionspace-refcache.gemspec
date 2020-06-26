# frozen_string_literal: true

require_relative 'lib/collectionspace/refcache/version'

Gem::Specification.new do |spec|
  spec.name          = 'collectionspace-refcache'
  spec.version       = CollectionSpace::RefCache::VERSION
  spec.authors       = ['Mark Cooper']
  spec.email         = ['mark.c.cooper@outlook.com']

  spec.summary       = 'CollectionSpace RefCache.'
  spec.description   = 'A caching system for CollectionSpace refnames.'
  spec.homepage      = 'https://github.org/collectionspace/collectionspace-refcache'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'collectionspace-client', '0.6.0'
  spec.add_dependency 'zache', '~> 0.12.0'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.85.1'
end
