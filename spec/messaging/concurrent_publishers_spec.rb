require "rails_helper"

RSpec.describe "Concurrent outbox publishers", type: :model do
  self.use_transactional_tests = false

  it "skips events locked by another worker instead of publishing them twice" do
    event = Messaging::OutboxEvent.transaction do
      Messaging::Outbox.record!(event_type: "triagem.aprovada", consulta_id: "concurrency-test", data: {})
    end
    entered = Queue.new
    release = Queue.new
    first = double("first publisher")
    allow(first).to receive(:publish) { entered << true; release.pop; true }
    second = double("second publisher")
    expect(second).not_to receive(:publish)

    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Messaging::PublishPending.new(publisher: first, batch_size: 1).call
      end
    end
    Timeout.timeout(5) { entered.pop }
    expect(Messaging::PublishPending.new(publisher: second, batch_size: 1).call).to eq(0)
    release << true
    Timeout.timeout(5) { thread.value }
    expect(event.reload.published_at).to be_present
  ensure
    release << true if release
    thread&.join(5)
    Messaging::OutboxEvent.where(id: event.id).delete_all if event
  end
end
