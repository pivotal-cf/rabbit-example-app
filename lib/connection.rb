require 'json'
require 'bunny'

module RabbitExample
  class Connection
    def initialize(ws)
      @ws = ws
    end

    def connect!
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']

      connection.start
      index = amqp_credentials['uris'].index(@sampled_uri) || 0
      color = %w(DarkMagenta DarkSalmon DarkViolet)[index] || 'Black'
      ws_puts "<b><font color='#{color}'>Starting connection to (#{@sampled_uri})</font></b><br/>\n"
    end

    def stop!
      connection.stop
    rescue => e
      puts_error "[ERROR] Connection failed to stop: #{e.message}."
    end

    private

    attr_reader :ws

    def queue
      @queue ||= channel.queue(queue_name, durable: true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      @connection ||= Bunny.new(
        @sampled_uri,
        tls_cert: './tls/client_certificate.pem',
        tls_key: './tls/client_key.pem',
        tls_ca_certificates: %w(./tls/ca_certificate.pem),
        verify_peer: false)
    rescue Bunny::TCPConnectionFailed => e
      puts_error "[ERROR] Connection to #{@sampled_uri} failed: #{e.message}."
    end

    def vcap_services
      @vcap_services ||= JSON.parse(ENV['VCAP_SERVICES'])
    end

    def queue_name
      ENV['QUEUE_NAME'] || 'testq'
    end

    def amqp_credentials
      protocols = vcap_services['p-rabbitmq'].first['credentials']['protocols']
      protocols['amqp+ssl'] || protocols['amqp']
    end

    def puts_success(msg)
      ws_puts "#{msg} <br />\n"
    end

    def puts_error(msg)
      ws_puts "<font color='red'>#{msg}</font><br />\n"
    end

    def puts_warning(msg)
      ws_puts "<font color='orange'>#{msg}</font><br />\n"
    end

    def ws_puts(msg)
      ws.send msg
      STDOUT.puts msg
    end
  end
end
