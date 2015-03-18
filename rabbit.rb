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
    out.puts "in the write loop"
    connect!(out)
    while true
      msg = DateTime.now.to_s
      queue.publish(msg, persistent: true)
      puts_success(out," [x] Sent #{msg}")
      out.flush
      sleep 2
    end
  rescue
    reset_connections(out)
    write_loop(out)
  end

  def read_loop(out)
    out.puts "in the read loop"
    connect!(out)
    queue.subscribe(block: true, manual_ack: true) do |delivery_info, _, body|
      channel.ack(delivery_info.delivery_tag)
      puts_success(out," [x] Received: #{body}")
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
    out.puts "hello!"
    # @sampled_uri = amqp_credentials["uris"].sample || amqp_credentials["uri"]
    @sampled_uri = amqp_credentials["uri"]
    out.puts @sampled_uri
    
    puts_connection(out,"Starting connection (#{@sampled_uri})")
    connection.start
  end

  def vcap_services
    @vcap_services ||= JSON.parse(ENV['VCAP_SERVICES'])
  end

  def queue_name
    ENV['QUEUE_NAME'] || "testq"
  end

  def reset_connections(out)
    puts_warning(out,"**** Restarting connection")
    connection.close
  rescue => error
    puts_error(out,"[ERROR] == #{error.message}")
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

  def puts_success(out,msg)
    out.puts "#{msg} <br />\n"
  end

  def puts_error(out,msg)
    out.puts "<font color = 'red'> #{msg} </font> <br />\n"
  end

  def puts_warning(out,msg)
    out.puts "<font color = 'orange'> #{msg} </font> <br />\n"
  end

  def puts_connection(out,msg)
    case amqp_credentials[uris].index(@sampled_uri)
      when 0
        html = "<b><font color = 'DarkMagenta'> #{msg} </font></b> <br />\n"
      when 1
        html = "<b><font color = 'DarkSalmon'> #{msg} </font></b> <br />\n"
      when 2
        html = "<b><font color = 'DarkViolet'> #{msg} </font></b> <br />\n"
      else
        html = "#{msg} <br />\n"
    end
    out.puts "msg"
    out.puts html
  end


end
