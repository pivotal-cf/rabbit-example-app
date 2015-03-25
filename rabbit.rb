require 'sinatra'
require 'sinatra/streaming'
require_relative 'lib/consumer'
require_relative 'lib/producer'

# 1. Find out how to set the timeout shorter
# 1. How can we stop the read subscribe

class Rabbit < Sinatra::Base
  helpers Sinatra::Streaming

  configure do
    set :server, :thin
    set :bind, '0.0.0.0'
    set :port, ENV.fetch('PORT', 4567)
  end

  get '/write' do
    stream do |out|
      producer = Producer.new(out)
      out.callback { producer.close! }
      producer.connect!
      producer.write until producer.closed?
    end
  end

  get '/read' do
    stream do |out|
      consumer = Consumer.new(out)
      out.callback { conumer.close! }
      consumer.connect!
      consumer.subscribe do |delivery_info, body|
        conumser.read(delivery_info, body)
      end
    end
  end
end
