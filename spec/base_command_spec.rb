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

  describe 'timeouts' do
    before { allow(Socket).to receive(:tcp).and_raise(SocketError, "stubbed") }

    it 'defaults to 5 seconds' do
      expect(Dalli::Elasticache::AutoDiscovery::ConfigCommand.new('example.com', 11_211).timeout).to eq(5)
    end

    it 'applies the timeout to DNS resolution as well as the TCP connect' do
      command = Dalli::Elasticache::AutoDiscovery::ConfigCommand.new('example.com', 11_211, 2)
      expect { command.response }.to raise_error(SocketError, "stubbed")
      expect(Socket).to have_received(:tcp).with('example.com', 11_211, connect_timeout: 2, resolv_timeout: 2)
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

    context 'when the response exceeds the size limit' do
      let(:timeout) { 3 }
      let(:limit) { Dalli::Elasticache::AutoDiscovery::BaseCommand::MAX_RESPONSE_BYTES }

      def response_within(seconds)
        result = Thread.new do
          command.response
        rescue StandardError => e
          e
        end
        result.join(seconds)&.value
      ensure
        result&.kill
      end

      it 'raises ResponseError on too many lines' do
        serve_once(server, "STAT filler 0123456789\r\n" * ((limit / 24) + 10))
        expect(response_within(2)).to be_a(Dalli::Elasticache::AutoDiscovery::ResponseError)
          .and(having_attributes(message: /exceeded #{limit} bytes/))
      end

      it 'raises ResponseError on a single line with no terminator' do
        serve_once(server, 'a' * (limit + 10))
        expect(response_within(2)).to be_a(Dalli::Elasticache::AutoDiscovery::ResponseError)
          .and(having_attributes(message: /exceeded #{limit} bytes/))
      end
    end

    it 'raises EOFError when the connection closes before END' do
      server_threads << Thread.new do
        client = server.accept
        client.readline
        client.write("CONFIG cluster 0 4\r\n12\r\n")
        client.close
      end
      expect { command.response }.to raise_error(EOFError)
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

    context 'when the server accepts the connection but never completes the handshake' do
      let(:certificate) { self_signed_certificate(key, 'IP:127.0.0.1') }
      let(:command) do
        Dalli::Elasticache::AutoDiscovery::ConfigCommand.new('127.0.0.1', server.addr[1], 0.5,
                                                             ssl_context: client_context)
      end

      it 'raises Timeout::Error once the timeout elapses' do
        serve_once(server, config_response) { |client| client.tap { sleep } }
        result = Thread.new do
          command.response
        rescue StandardError => e
          e
        end

        expect(result.join(3)&.value).to be_a(Timeout::Error)
        expect(result.value.message).to match(/TLS handshake timed out after 0.5s/)
      ensure
        result&.kill
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
