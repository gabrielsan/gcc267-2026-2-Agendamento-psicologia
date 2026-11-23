namespace :messaging do
  desc "Declare durable exchanges, queues and bindings"
  task setup: :environment do
    connection = Bunny.new(ENV.fetch("RABBITMQ_URL"))
    begin
      connection.start
      Messaging::Topology.declare(connection.create_channel)
      puts "RabbitMQ topology ready"
    ensure
      connection.close if connection.open?
    end
  end

  desc "Publish pending outbox events once"
  task publish_once: :environment do
    publisher = Messaging::RabbitPublisher.new
    begin
      puts "Processed: #{Messaging::PublishPending.new(publisher: publisher).call}"
    ensure
      publisher.close
    end
  end

  desc "Run outbox publisher (SIGTERM/SIGINT stop gracefully)"
  task publish: :environment do
    stopping = false
    %w[TERM INT].each { |signal| Signal.trap(signal) { stopping = true } }
    publisher = Messaging::RabbitPublisher.new
    begin
      FileUtils.mkdir_p(Rails.root.join("tmp"))
      until stopping
        begin
          Messaging::PublishPending.new(publisher: publisher, batch_size: 5).call
          FileUtils.touch(Rails.root.join("tmp/outbox-heartbeat"))
        rescue StandardError => error
          Rails.logger.error("outbox worker error=#{error.class.name}")
        end
        sleep ENV.fetch("OUTBOX_POLL_SECONDS", "1").to_f unless stopping
      end
    ensure
      publisher.close
    end
  end
end
