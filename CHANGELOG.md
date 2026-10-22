# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `Endpoint` and the command classes now default to a 5 second timeout, matching `Dalli::ElastiCache`. Previously they had no timeout unless one was passed. Pass `timeout: nil` to disable it. [@petergoldstein](https://github.com/petergoldstein)

### Fixed

- Bracketed IPv6 configuration endpoints (e.g. `[::1]:11211`) were parsed but could never connect, because the brackets were passed through to address resolution. The brackets are now stripped before connecting, and SNI is no longer set when the host is an IP literal. [@petergoldstein](https://github.com/petergoldstein)
- An `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR` reply from the endpoint was not recognized, so discovery blocked until the read timeout (or indefinitely with `timeout: nil`). These replies now raise `Dalli::Elasticache::AutoDiscovery::ResponseError` immediately. The response terminator is now matched exactly instead of any line containing `END`. [@petergoldstein](https://github.com/petergoldstein)
- The TLS handshake with the configuration endpoint had no timeout, so an endpoint that accepted the TCP connection but never completed the handshake blocked discovery indefinitely, regardless of `timeout:`. The handshake is now bounded by `timeout:` and raises `Timeout::Error`. [@petergoldstein](https://github.com/petergoldstein)
- Node lists from IPv6 clusters, nodes reported without an IP address, and hostnames containing underscores were silently parsed as an empty list, producing a Dalli client with no servers that only failed on first use with `Dalli::RingError`. These nodes now parse correctly, and `#servers` (and therefore `#client`) raises `Dalli::Elasticache::AutoDiscovery::ResponseError` if a response contains no nodes. [@petergoldstein](https://github.com/petergoldstein)
- The configuration endpoint address was validated with line anchors, so a string containing a newline (e.g. `"junk\nhost:11211"`) parsed using one of its lines. Ports outside 1–65535 were also accepted. Both now raise `ArgumentError`. [@petergoldstein](https://github.com/petergoldstein)
- `Node#==` raised `NoMethodError` when compared with an object that is not a `Node`. It now returns `false`. [@petergoldstein](https://github.com/petergoldstein)
- Concurrent first calls to `Endpoint#config` or `Endpoint#stats` each ran their own network call. They now share one. [@petergoldstein](https://github.com/petergoldstein)
- `timeout:` now also bounds DNS resolution of the configuration endpoint (`resolv_timeout:`), not just the TCP connect. [@petergoldstein](https://github.com/petergoldstein)

### Security

- With `ssl_context:` set to `VERIFY_PEER`, the endpoint certificate was checked against the trusted CAs but not against the endpoint hostname, because `SSLContext.new` leaves `verify_hostname` false. Any certificate from a trusted CA was accepted for any host. The hostname (or IP address) is now verified whenever `verify_mode` includes `VERIFY_PEER`, even if `verify_hostname` is false, since an explicit `false` can't be distinguished from the default. Connections that relied on a certificate not matching the endpoint host will now fail. [@petergoldstein](https://github.com/petergoldstein)
- Discovery responses are now limited to 1 MB. Previously a misbehaving endpoint could send an unbounded response (or a single line with no terminator) and the client buffered all of it until the read timeout, or indefinitely with `timeout: nil`. Larger responses raise `Dalli::Elasticache::AutoDiscovery::ResponseError`. [@petergoldstein](https://github.com/petergoldstein)

## [2.0.2]

### Fixed

- Read timeout over TLS (`ssl_context:`) could block for the full timeout on every line after the first. `wait_readable` polled the raw TCP fd for readiness, which can't see data already buffered above it by OpenSSL, so it waited out the full timeout instead of returning immediately. Read timeouts are now enforced as a single deadline around the whole response rather than gating each line's readiness. [@petergoldstein](https://github.com/petergoldstein)

## [2.0.1]

### Fixed

- TLS support via `ssl_context:` keyword argument was advertised in v2.0.0 but was not included in the published gem due to a tagging error. [@petergoldstein](https://github.com/petergoldstein)

## [2.0.0]

### Added

- TCP connect and read timeout (default 5s) for auto-discovery calls. [@petergoldstein](https://github.com/petergoldstein)
- IPv6 endpoint support (bracketed addresses like `[::1]:11211`). [@petergoldstein](https://github.com/petergoldstein)
- TLS support for auto-discovery endpoint via `ssl_context:` keyword argument. [@petergoldstein](https://github.com/petergoldstein)

### Removed

- Legacy config command path for engines < 1.4.14. [@petergoldstein](https://github.com/petergoldstein)
- Support for Ruby < 3.3. [@petergoldstein](https://github.com/petergoldstein)

### Changed

- Fix `Dalli::Socket` shadowing `::Socket` in `BaseCommand`. [@petergoldstein](https://github.com/petergoldstein)
- Version requirements: Ruby v3.3+, and Dalli v5.0+. [@petergoldstein](https://github.com/petergoldstein)

## [1.0.1]

### Fixed

- Loading error because of incorrect path in a require_relative.  [@petervandoros](https://github.com/petervandoros)

## [1.0.0]

### Added

- Rubocop linting. [@petergoldstein](https://github.com/petergoldstein)
- Specs for reading data off the socket, to ensure that code functions as expected. [@petergoldstein](https://github.com/petergoldstein)
- This CHANGELOG.md. [@petergoldstein](https://github.com/petergoldstein)
- Support for Google Cloud MemoryStore. [@petergoldstein](https://github.com/petergoldstein)

### Fixed

- Parsing error when retrieving the version.  Version string is now parsed correctly. [@petergoldstein](https://github.com/petergoldstein)
- Library would error when the engine version was non-numeric or included additional data.  Now treats such situations as a "modern" engine version. [@petergoldstein](https://github.com/petergoldstein)

### Changed

- BREAKING: engine_version is now returned as a string rather than a Gem::Version to support potentially non-numeric versions. [@petergoldstein](https://github.com/petergoldstein)
- Updated README to reflect deprecation of DalliStore and preferred use of MemCacheStore. [@xiaoronglv](https://github.com/xiaoronglv)
- Switched to GitHub Actions from Travis for CI. Added Ruby 2.6, 2.7, 3.0, 3.1, ruby-head, jruby-9.3, jruby-head. [@petergoldstein](https://github.com/petergoldstein)
- Dalli::Elasticache now raises an ArgumentError if it cannot parse the config endpoint argument. [@petergoldstein](https://github.com/petergoldstein)
- Now use default port of 11211 for configuration endpoint when not explicitly specified. [@petergoldstein](https://github.com/petergoldstein)
- Refactored internal classes to better enable testing, shrink individual class responsibilities. [@petergoldstein](https://github.com/petergoldstein)
- Allow underscores in hostnames.

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

