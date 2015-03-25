require_relative 'connection'

module RabbitExample
  class Producer < Connection
    def write
      msg = DateTime.now.to_s
      queue.publish msg, persistent: true
      puts_success "Sent #{msg}"
      sleep sleep_time
    rescue => e
      puts_warn "Write failed: #{e.message}"
      close!
    end

    private

    def sleep_time
      ENV['SLEEP_TIME'] || 2
    end
  end
end
