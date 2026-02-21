# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle exec rake          # Run all tests (default task)
bundle exec rspec         # Run all specs
bundle exec rspec spec/config_response_spec.rb  # Run a single spec file
bundle exec rubocop       # Lint
bundle exec rubocop -a    # Lint with auto-fix
```

## Architecture

This gem connects [Dalli](https://github.com/petergoldstein/dalli) (a Ruby memcached client) to AWS ElastiCache / Google Cloud MemoryStore auto-discovery endpoints. Given a cluster configuration endpoint, it queries that endpoint over TCP to discover all cache nodes, then provides server addresses to Dalli.

### Module structure

All classes live under `Dalli::Elasticache::AutoDiscovery` (note: `Elasticache` module uses lowercase 'c', while the top-level `ElastiCache` class uses uppercase 'C').

**Entry point:** `Dalli::ElastiCache` (`lib/dalli/elasticache.rb`) — accepts a config endpoint + Dalli options + optional `timeout:`, delegates to `Endpoint` for discovery, and exposes `#client`, `#servers`, `#version`, `#engine_version`, `#refresh`.

**Discovery flow:**
1. `Endpoint` parses the host:port (DNS, IPv4, or bracketed IPv6), then lazily runs two TCP commands against the memcached config endpoint
2. `StatsCommand` → sends `stats\r\n` → parses response via `StatsResponse` to extract `engine_version`
3. `ConfigCommand` → sends `config get cluster\r\n` → parses response via `ConfigResponse` to extract cluster version and `Node` list
4. `Node` represents a single cache node (host, ip, port); `#to_s` returns `"host:port"` for Dalli

`BaseCommand` contains the shared TCP socket logic — uses `::Socket.tcp` with connect timeout and `wait_readable` for read timeout (default 5s). The `::Socket` qualification is required because Dalli 5.0 defines `Dalli::Socket` which shadows the top-level constant.

### Testing approach

Tests stub TCP connections entirely — no live ElastiCache endpoint needed. Specs stub `Socket.tcp` (not `TCPSocket.new`). Raw response strings test parsing logic. `Faker` is available for generating test data.

## Style

- RuboCop with `rubocop-performance`, `rubocop-rake`, `rubocop-rspec` plugins
- Target Ruby version: 3.3
- All files use `# frozen_string_literal: true`
