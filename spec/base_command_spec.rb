# frozen_string_literal: true

require_relative 'spec_helper'

# These specs run against real local sockets rather than stubs, so they exercise
# address resolution, the TLS handshake, and certificate verification end to end.
describe 'Dalli::Elasticache::AutoDiscovery::BaseCommand' do
  let(:config_response) do
    "CONFIG cluster 0 52\r\n12\r\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211\r\n\r\nEND\r\n"
  end
  let(:server_threads) { [] }

  after { server_threads.each(&:kill) }

  # Accepts one connection, reads the command line, and writes `response`.
  # A block, if given, wraps the accepted socket (e.g. in TLS) before use.
  def serve_once(server, response)
    server_threads << Thread.new do
      client = server.accept
      client = yield(client) if block_given?
      client.readline
      client.write(response)
      sleep
    rescue StandardError
      # The client may hang up mid-handshake or before reading the response
    ensure
      [client, server].compact.each(&:close)
    end
  end

  describe 'bracketed IPv6 endpoints' do
    let(:server) do
      TCPServer.new('::1', 0)
    rescue SystemCallError
      skip 'IPv6 loopback is not available'
    end
    let(:endpoint) { Dalli::Elasticache::AutoDiscovery::Endpoint.new("[::1]:#{server.addr[1]}", timeout: 2) }

    it 'connects to the unbracketed address' do
      serve_once(server, config_response)
      expect(endpoint.host).to eq('[::1]')
      expect(endpoint.config.version).to eq(12)
      expect(endpoint.config.nodes.map(&:to_s)).to eq(['mycluster.0001.cache.amazonaws.com:11211'])
    end
  end

  describe 'error responses' do
    let(:server) { TCPServer.new('127.0.0.1', 0) }
    let(:command) do
      Dalli::Elasticache::AutoDiscovery::ConfigCommand.new('127.0.0.1', server.addr[1], timeout)
    end
    let(:timeout) { 1 }

    ["ERROR\r\n", "CLIENT_ERROR bad command line format\r\n", "SERVER_ERROR out of memory\r\n"].each do |error_line|
      it "raises ResponseError immediately on #{error_line.strip.inspect}" do
        serve_once(server, error_line)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        expect { command.response }.to raise_error(
          Dalli::Elasticache::AutoDiscovery::ResponseError, /#{Regexp.escape(error_line.strip)}/
        )
        expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < timeout
      end
    end

    context 'without a timeout' do
      let(:timeout) { nil }

      it 'raises instead of blocking forever' do
        serve_once(server, "ERROR\r\n")
        result = Thread.new do
          command.response
        rescue StandardError => e
          e
        end

        expect(result.join(2)&.value).to be_a(Dalli::Elasticache::AutoDiscovery::ResponseError)
      ensure
        result&.kill
      end
    end

    it 'only treats an exact END line as the terminator' do
      serve_once(server, "STAT weird_END_stat 1\r\nSTAT version 1.6.12\r\nEND\r\n")
      stats = Dalli::Elasticache::AutoDiscovery::StatsCommand.new('127.0.0.1', server.addr[1], timeout).response
      expect(stats.engine_version).to eq('1.6.12')
    end
  end

  describe 'TLS certificate verification' do
    let(:key) { OpenSSL::PKey::EC.generate('prime256v1') }
    let(:server) { TCPServer.new('127.0.0.1', 0) }
    let(:server_context) do
      OpenSSL::SSL::SSLContext.new.tap do |ctx|
        ctx.cert = certificate
        ctx.key = key
      end
    end
    # Configured the way the README documents: VERIFY_PEER, but verify_hostname
    # left at its SSLContext.new default of false.
    let(:client_context) do
      OpenSSL::SSL::SSLContext.new.tap do |ctx|
        ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
        ctx.cert_store = OpenSSL::X509::Store.new.tap { |store| store.add_cert(certificate) }
      end
    end
    let(:command) do
      Dalli::Elasticache::AutoDiscovery::ConfigCommand.new('127.0.0.1', server.addr[1], 2, ssl_context: client_context)
    end

    def self_signed_certificate(key, subject_alt_name)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=dalli-elasticache-test')
      cert.public_key = key
      cert.not_before = Time.now - 60
      cert.not_after = Time.now + 3600
      add_extensions(cert, 'basicConstraints' => 'CA:TRUE', 'subjectAltName' => subject_alt_name)
      cert.sign(key, 'SHA256')
    end

    def add_extensions(cert, extensions)
      factory = OpenSSL::X509::ExtensionFactory.new(cert, cert)
      extensions.each { |name, value| cert.add_extension(factory.create_extension(name, value)) }
    end

    def serve_tls
      serve_once(server, config_response) do |client|
        OpenSSL::SSL::SSLSocket.new(client, server_context).tap(&:accept)
      end
    end

    context 'when the certificate matches the host' do
      let(:certificate) { self_signed_certificate(key, 'IP:127.0.0.1') }

      it 'returns the config' do
        serve_tls
        expect(command.response.version).to eq(12)
      end
    end

    context 'when the certificate was issued for a different host' do
      let(:certificate) { self_signed_certificate(key, 'DNS:other.example.com') }

      it 'rejects the connection' do
        serve_tls
        expect { command.response }.to raise_error(OpenSSL::SSL::SSLError, /hostname/)
      end
    end

    context 'when the client context does not verify the peer' do
      let(:certificate) { self_signed_certificate(key, 'DNS:other.example.com') }
      let(:client_context) { OpenSSL::SSL::SSLContext.new }

      it 'skips hostname verification' do
        serve_tls
        expect(command.response.version).to eq(12)
      end
    end
  end
end
