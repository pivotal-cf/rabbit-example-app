require_relative 'connection'

module RabbitExample
  class Producer < Connection
    def write
      msg = DateTime.now.to_s
      queue.publish msg, persistent: true
      puts_success "Sent #{msg}"
      sleep sleep_time
    rescue => e
      puts_warning "Write failed: #{e.message}"
      restart!
    end

    private

    def sleep_time
      ENV['SLEEP_TIME'] || 2
    end
  end
end
