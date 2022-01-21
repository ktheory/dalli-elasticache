# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added 

- Rubocop linting. [@petergoldstein](https://github.com/petergoldstein)
- Specs for reading data off the socket, to ensure that code functions as expected. [@petergoldstein](https://github.com/petergoldstein)
- This CHANGELOG.md. [@petergoldstein](https://github.com/petergoldstein)
- Support for Google Memory Cloud. [@petergoldstein](https://github.com/petergoldstein)

### Fixed

- Parsing error when retrieving the version.  Version string is now parsed correctly. [@petergoldstein](https://github.com/petergoldstein)
- Library would error when the engine version was non-numeric or included additional data.  Now treats such situations as a "modern" engine version. [@petergoldstein](https://github.com/petergoldstein)

### Changed

- BREAKING: engine_version is now returned as a string rather than a Gem::Version to support potentially non-numeric versions. [@petergoldstein](https://github.com/petergoldstein)
- Updated README to reflect deprecation of DalliStore and preferred use of MemCacheStore. [@xiaoronglv](https://github.com/xiaoronglv)
- Switched to GitHub Actions from Travis for CI. [@petergoldstein](https://github.com/petergoldstein)
- Dalli::Elasticache now raises an ArgumentError if it cannot parse the config endpoint argument. [@petergoldstein](https://github.com/petergoldstein)
- Now use default port of 11211 for configuration endpoint when not explicitly specified. [@petergoldstein](https://github.com/petergoldstein)
- Refactored internal classes to better enable testing, shrink individual class responsibilities. [@petergoldstein](https://github.com/petergoldstein)

### Removed

- Support for all Rubies before 2.6 was dropped. [@petergoldstein](https://github.com/petergoldstein)


## [0.2.0] - 2016-02-24

### Changed

- Node connections now use hostnames as opposed to IPs (which may change over time). [@BanjoInc](https://github.com/BanjoInc)
- Ruby 2.2 and 2.3 was added to CI. [@ktheory](https://github.com/ktheory)

### Removed

- Support for Ruby 1.9.2 and 1.9.3 was dropped. [@ktheory](https://github.com/ktheory)

## [0.1.2] - 2014-07-08

### Changed

- Added Ruby 2.0 and 2.1 to CI. [@petergoldstein](https://github.com/petergoldstein)

### Fixed

- Addressed NameError on refresh. [@ryo0301](https://github.com/ryo0301)

## [0.1.1] - 2014-05-03

### Added

- Ability to retrieve configuration version (indication of how many times the node set has changed) from endpoint. [@zmillman](https://github.com/zmillman)
- Specs for existing functionality. [@zmillman](https://github.com/zmillman)
- Continuous Integration using Travis CI. [@zmillman](https://github.com/zmillman)
- Refresh capability for the node set. [@zmillman](https://github.com/zmillman)

### Changed

- Refactoring and repackaging of the endpoint classes. [@zmillman](https://github.com/zmillman)


## [0.1.0] - 2013-01-27

### Added

- Initial implementation for fetching node addresses from an Amazon ElastiCache endpoint. [@ktheory](https://github.com/ktheory)

