# frozen_string_literal: true

require_relative 'lib/dalli/elasticache/version'

Gem::Specification.new do |s|
  s.name     = 'dalli-elasticache'
  s.version  = Dalli::ElastiCache::VERSION
  s.licenses = ['MIT']

  s.summary     = "Configure Dalli clients with ElastiCache's AutoDiscovery"
  s.description = <<-DESC
    This gem provides an interface for fetching cluster information from an AWS
    ElastiCache AutoDiscovery server and configuring a Dalli client to connect
    to all nodes in the cache cluster.
  DESC

  s.authors     = ['Aaron Suggs', 'Zach Millman', 'Peter M. Goldstein']
  s.email       = ['aaron@ktheory.com', 'zach@magoosh.com', 'peter.m.goldstein@gmail.com']
  s.homepage    = 'https://github.com/ktheory/dalli-elasticache'

  s.files         = Dir.glob('{bin,lib}/**/*').select { |f| File.file?(f) } +
                    %w[CHANGELOG.md LICENSE README.md Rakefile]
  s.rdoc_options  = ['--charset=UTF-8']
  s.require_paths = ['lib']

  s.required_ruby_version     = '>= 3.3.0'
  s.required_rubygems_version = '>= 1.3.5'

  s.add_dependency 'dalli', '>= 5.0.0'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['source_code_uri'] = s.homepage
  s.metadata['changelog_uri'] = "#{s.homepage}/blob/master/CHANGELOG.md"
end
