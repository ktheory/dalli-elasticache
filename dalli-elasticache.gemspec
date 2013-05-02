# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'dalli/elasticache/version'

Gem::Specification.new do |s|
  s.name = 'dalli-elasticache'
  s.version = Dalli::ElastiCache::VERSION

  s.authors = ["Aaron Suggs"]
  s.description = "A wrapper for Dalli with support for AWS ElastiCache Auto Discovery"
  s.email = "aaron@ktheory.com"
  s.required_rubygems_version = ">= 1.3.5"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.md Rakefile)
  s.homepage = 'http://github.com/ktheory/dalli-elasticache'
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = "Adds AWS ElastiCache Auto Discovery support to Dalli memcache client"
  s.test_files = Dir.glob("{test,spec}/**/*")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '= 2.13.0'

  s.add_dependency 'dalli', ">= 1.0.0" # ??
end

