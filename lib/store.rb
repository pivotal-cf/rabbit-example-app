require 'json'
require 'bunny'

module RabbitExample
  class Store
    attr_reader :queue_name

    def initialize(queue_name = ENV['QUEUE_NAME'] || 'storeq')
      @queue_name = queue_name
    end

    def write(msg)
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']
      connection.start
      queue.publish msg, persistent: true
    rescue => e
      clear_connection_state
      raise StandardError.new("[ERROR] Store::write: #{e.message}.")
    end

    def read
      @sampled_uri = amqp_credentials['uris'].sample || amqp_credentials['uri']
      connection.start
      queue.pop[2]
    rescue => e
      clear_connection_state
      raise StandardError.new("[ERROR] Store::read: #{e.message}.")
    end

    private

    def queue_options
      JSON.parse(
        ENV['QUEUE_OPTS'] || '{"durable":true}',
        symbolize_names: true
      )
    end

    def clear_connection_state
      @connection = @channel = @queue = nil
    end

    def queue
      @queue ||= channel.queue(queue_name, queue_options)
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

    def amqp_credentials
      protocols = extract_credentials(vcap_services)['protocols']
      protocols['amqp+ssl'] || protocols['amqp']
    end

    def extract_credentials(vcap_services)
      vcap_services.each do |service_key, service|
        service.each do |element|
          return element["credentials"] if element["tags"].include?("rabbitmq")
        end
      end

      raise "no rabbitmq tag found!"
    end
  end
end
