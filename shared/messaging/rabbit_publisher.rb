module Messaging
  class RabbitPublisher
    class NotConfirmed < StandardError; end
    class Unroutable < StandardError; end

    def publish(event)
      connect unless @connection&.open?
      @returned = false
      @exchange.publish(JSON.generate(event.envelope),
        routing_key: event.event_type, persistent: true, mandatory: true,
        content_type: "application/json", message_id: event.event_id,
        type: event.event_type, app_id: event.producer)
      confirmed = Timeout.timeout(10, NotConfirmed) { @channel.wait_for_confirms }
      raise NotConfirmed unless confirmed
      raise Unroutable if @returned
      true
    rescue StandardError
      close
      raise
    end

    def close
      @connection.close if @connection&.open?
    ensure
      @connection = nil
    end

    private

    def connect
      @connection = Bunny.new(ENV.fetch("RABBITMQ_URL"),
        automatically_recover: false, connection_timeout: 5,
        read_timeout: 5, write_timeout: 5, continuation_timeout: 5_000,
        heartbeat: 10, logger: Rails.logger)
      @connection.start
      @channel = @connection.create_channel
      @channel.confirm_select
      @exchange = Topology.declare(@channel)
      @exchange.on_return { |_info, _properties, _body| @returned = true }
    end
  end
end
