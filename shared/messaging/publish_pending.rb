module Messaging
  class PublishPending
    def initialize(publisher: RabbitPublisher.new, batch_size: 100)
      @publisher = publisher
      @batch_size = batch_size
    end

    def call
      processed = 0
      @batch_size.times do
        found = OutboxEvent.transaction do
          # Lock remains held until the confirm and DB update; competing workers skip it.
          event = OutboxEvent.pending.order(:id).lock("FOR UPDATE SKIP LOCKED").first
          next false unless event

          begin
            @publisher.publish(event)
          rescue StandardError => error
            attempts = event.attempts + 1
            event.update!(attempts: attempts, last_error: error.class.name,
              available_at: Time.current + [2**[attempts, 9].min, 300].min.seconds)
            Rails.logger.warn("outbox retry event_id=#{event.event_id} error=#{error.class.name}")
          else
            event.update!(published_at: Time.current, attempts: event.attempts + 1, last_error: nil)
          end
          true
        end
        break unless found
        processed += 1
      end
      processed
    end
  end
end
