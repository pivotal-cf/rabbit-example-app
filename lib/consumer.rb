require_relative 'connection'

module RabbitExample
  class Consumer < Connection
    def subscribe
      queue.subscribe(block: true, manual_ack: true) do |delivery_info, _, body|
        read delivery_info, body
      end
    end

    private

    def read(delivery_info, body)
      channel.ack delivery_info.delivery_tag
      puts_success "Received: #{body}"
    rescue => e
      puts_warn "Read failed: #{e.message}"
      close!
    end
  end
end
