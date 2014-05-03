# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'dalli/elasticache/version'

Gem::Specification.new do |s|
  s.name     = 'dalli-elasticache'
  s.version  = Dalli::ElastiCache::VERSION
  s.licenses = ['MIT']
  
  s.summary     = "Configure Dalli clients with ElastiCache's AutoDiscovery"
  s.description = <<-EOS
    This gem provides an interface for fetching cluster information from an AWS
    ElastiCache AutoDiscovery server and configuring a Dalli client to connect
    to all nodes in the cache cluster.
  EOS
  
  s.authors     = ["Aaron Suggs", "Zach Millman"]
  s.email       = ["aaron@ktheory.com", "zach@magoosh.com"]
  s.homepage    = 'http://github.com/ktheory/dalli-elasticache'
  
  s.files         = Dir.glob("{bin,lib}/**/*") + %w(README.md Rakefile)
  s.rdoc_options  = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.test_files    = Dir.glob("{test,spec}/**/*")
  
  s.required_ruby_version     = '>= 1.9.2' # Maybe less?
  s.required_rubygems_version = '>= 1.3.5'
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_dependency 'dalli', ">= 1.0.0" # ??
end
