# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Gem::Specification' do
  context 'when loaded from dalli-elasticache.gemspec' do
    let(:spec) { Gem::Specification.load(File.expand_path('../dalli-elasticache.gemspec', __dir__)) }

    it 'packages the license, changelog, and readme with the library' do
      expect(spec.files).to include('LICENSE', 'CHANGELOG.md', 'README.md')
      expect(spec.files).to include('lib/dalli/elasticache.rb')
    end

    it 'links to the source and changelog over https' do
      expect(spec.homepage).to start_with('https://')
      expect(spec.metadata).to include(
        'source_code_uri' => 'https://github.com/ktheory/dalli-elasticache',
        'changelog_uri' => 'https://github.com/ktheory/dalli-elasticache/blob/master/CHANGELOG.md'
      )
    end
  end
end
