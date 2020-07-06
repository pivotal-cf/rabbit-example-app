require 'json'
require 'bunny'
require 'uaa'

module RabbitExample
  class Connection
    def initialize(ws)
      @ws = ws
    end

    def start!
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']

      connection.start
      index = amqp_credentials['uris'].index(@sampled_uri)
      ws_puts "<b><font color='DarkMagenta'>Connected to #{@sampled_uri} (index #{index})</font></b><br/>\n"
    rescue => e
      puts_error "[ERROR] Connection #{@sampled_uri} failed to start: #{e.message}."
      clear_connection_state
      unless closed?
        sleep 2
        retry
      end
    end

    def stop!
      connection.stop
      clear_connection_state
    rescue => e
      puts_error "[ERROR] Connection #{@sampled_uri} failed to stop: #{e.message}."
    end

    def restart!
      puts_warning 'Trying to reconnect'
      stop!
      start!
    end

    def closed?
      ws.state == :closed
    end

    private

    attr_reader :ws

    def clear_connection_state
      @connection = @channel = @queue = nil
    end

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
        verify_peer: false,
        password: @jwt_token
      )
    end

    def vcap_services
      @vcap_services ||= JSON.parse(ENV['VCAP_SERVICES'])
    end

    def queue_name
      ENV['QUEUE_NAME'] || 'testq'
    end

    def amqp_credentials
      protocols = extract_rabbitmq_credentials(vcap_services)['protocols']
      protocols['amqp+ssl'] || protocols['amqp']
    end

    def extract_rabbitmq_credentials(vcap_services)
      vcap_services.each do |service_key, service|
        service.each do |element|
          return element["credentials"] if element["tags"].include?("rabbitmq")
        end
      end

      raise "no rabbitmq tag found!"
    end

    def uaa_credentials
      @uaa_credentials = extract_uaa_credentials(vcap_services)
    end

    def extract_uaa_credentials(vcap_services)
      vcap_services.each do |service_key, service|
        service.each do |element|
          return element["credentials"] if element["label"].equal?("p-identity")
        end
      end

      raise "no p-identity binding found!"
    end

    def jwt_token
      @jwt_token ||= CF::UAA::TokenIssuer.new(
        uaa_credentials.auth_domain,
        uaa_credentials.client_id,
        uaa_credentials.client_secret
      ).client_credentials_grant
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
