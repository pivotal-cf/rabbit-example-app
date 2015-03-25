require 'sinatra'
require 'sinatra-websocket'
require_relative 'consumer'
require_relative 'producer'

module RabbitExample
  class Server < Sinatra::Base
    configure do
      set :server, :thin
      set :bind, '0.0.0.0'
      set :port, ENV.fetch('PORT', 4567)
      enable :inline_templates
    end

    get '/write' do
      start_websocket do |ws|
        producer = Producer.new(ws)
        ws.onclose { producer.stop! }
        ws.onopen do
          producer.connect!
          producer.write until ws.state == :closed
        end
      end
    end

    get '/read' do
      start_websocket do |ws|
        consumer = Consumer.new(ws)
        ws.onclose { consumer.stop! }
        ws.onopen do
          consumer.connect!
          consumer.subscribe
        end
      end
    end

    def start_websocket(&block)
      request.websocket? ? request.websocket(&block) : erb(:index)
    end
  end
end

__END__
@@ index
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Simple RabbitMQ Example</title>
  <link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
  <div class="container">
    <div class="page-header">
      <h1>Simple RabbitMQ Example <small><%= request.path_info[1..-1] %></small></h1>
    </div>
    <ul id="msgs"></ul>
  </div>
</body>

<script type="text/javascript">
  window.onload = function() {
    var ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
    ws.onmessage = function(m) {
      var el = document.getElementById('msgs'),
        node = document.createElement('LI');
      node.innerHTML = m.data;
      el.appendChild(node);
    };
  }
</script>
</html>
