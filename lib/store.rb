require 'json'
require 'bunny'

module RabbitExample
  class Store
    def write(msg)
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']
      connection.start
      queue.publish msg, persistent: true
    rescue => e
      clear_connection_state
      "[ERROR] Store::write: #{e.message}."
    end

    def read
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']
      connection.start
      queue.pop[2]
    rescue => e
      clear_connection_state
      "[ERROR] Store::read: #{e.message}."
    end

    private

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
        verify_peer: false)
    end

    def vcap_services
      @vcap_services ||= JSON.parse(ENV['VCAP_SERVICES'])
    end

    def queue_name
      ENV['QUEUE_NAME'] || 'storeq'
    end

    def amqp_credentials
      protocols = vcap_services['p-rabbitmq'].first['credentials']['protocols']
      protocols['amqp+ssl'] || protocols['amqp']
    end
  end
end

