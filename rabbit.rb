require 'sinatra'
require 'json'
require 'bunny'
require "sinatra/streaming"

class Rabbit < Sinatra::Base
  helpers Sinatra::Streaming

  configure do
    set :server, :puma
    set :bind,   "0.0.0.0"
    set :port,   ENV.fetch("PORT", 4567)
  end

  get "/write" do
    stream(:keep_open) do |out|
      write_loop(out)
    end
  end

  get "/read" do
    stream(:keep_open) do |out|
      read_loop(out)
    end
  end

  def write_loop(out)
    connect!(out)
    while true
      msg = DateTime.now.to_s
      queue.publish(msg, persistent: true)
      out.puts(" [x] Sent #{msg}<br />\n")
      out.flush
      sleep 2
    end
  rescue
    reset_connections(out)
    write_loop(out)
  end

  def read_loop(out)
    connect!(out)
    queue.subscribe(block: true, manual_ack: true) do |delivery_info, _, body|
      channel.ack(delivery_info.delivery_tag)
      out.puts(" [x] Received: #{body}<br />\n")
      out.flush
    end
  rescue
    reset_connections(out)
    read_loop(out)
  end

  def queue
    @queue ||= channel.queue(queue_name, durable: true)
  end

  def channel
    @channel ||= connection.create_channel
  end

  def connection
    @conn ||= Bunny.new(
      @sampled_uri,
      :tls_cert            => "./tls/client_certificate.pem",
      :tls_key             => "./tls/client_key.pem",
      :tls_ca_certificates => ["./tls/ca_certificate.pem"],
      :verify_peer         => false)
  end

  def connect!(out)
    @sampled_uri = amqp_credentials["uris"].sample
    out.puts("Starting connection (#{@sampled_uri})<br />\n")
    connection.start
  end

  def vcap_services
    @vcap_services ||= JSON.parse(ENV['VCAP_SERVICES'])
  end

  def queue_name
    ENV['QUEUE_NAME'] || "testq"
  end

  def reset_connections(out)
    out.puts("**** Restarting connection<br \>\n")
    connection.close
  rescue => error
    puts "[ERROR] == #{error.message}\n"
  ensure
    @conn = nil
    @channel = nil
    @queue = nil
    sleep 3
  end

  def amqp_credentials
    vcap_services["p-rabbitmq"].first["credentials"]["protocols"]["amqp+ssl"] ||
      vcap_services["p-rabbitmq"].first["credentials"]["protocols"]["amqp"]
  end

end
