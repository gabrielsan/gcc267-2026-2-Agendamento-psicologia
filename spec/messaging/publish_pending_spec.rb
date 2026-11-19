require "rails_helper"

RSpec.describe Messaging::PublishPending do
  let!(:event) do
    Messaging::Outbox.record!(event_type: "triagem.aprovada", consulta_id: "42", data: {})
  end
  let(:publisher) { instance_double(Messaging::RabbitPublisher, publish: true) }
  subject(:worker) { described_class.new(publisher: publisher) }

  it "marks an event published only after the broker confirms" do
    expect(publisher).to receive(:publish) do |pending|
      expect(pending.published_at).to be_nil
      true
    end
    expect(worker.call).to eq(1)
    expect(event.reload.published_at).to be_present
    expect(worker.call).to eq(0)
  end

  it "keeps a failed event pending and retries with the same event_id after backoff" do
    original_id = event.event_id
    allow(publisher).to receive(:publish).and_raise(Messaging::RabbitPublisher::NotConfirmed)
    worker.call
    expect(event.reload).to have_attributes(published_at: nil, attempts: 1,
      last_error: "Messaging::RabbitPublisher::NotConfirmed")
    expect(event.available_at).to be > Time.current
    expect(worker.call).to eq(0)

    travel 3.seconds do
      allow(publisher).to receive(:publish).and_return(true)
      expect(worker.call).to eq(1)
    end
    expect(event.reload.event_id).to eq(original_id)
    expect(event.published_at).to be_present
    expect(event.last_error).to be_nil
  end

  it "bounds batches and continues after one unavailable broker attempt" do
    Messaging::Outbox.record!(event_type: "triagem.reprovada", consulta_id: "43", data: {})
    allow(publisher).to receive(:publish).and_raise(IOError)
    expect(described_class.new(publisher: publisher, batch_size: 1).call).to eq(1)
    expect(Messaging::OutboxEvent.where(attempts: 0).count).to eq(1)
  end

  it "does not claim future retries" do
    event.update!(available_at: 1.hour.from_now)
    expect(publisher).not_to receive(:publish)
    expect(worker.call).to eq(0)
  end

  it "retries with the same id if the DB write fails after the broker confirm" do
    allow_any_instance_of(Messaging::OutboxEvent).to receive(:update!).and_raise(IOError)
    expect { worker.call }.to raise_error(IOError)
    expect(event.reload.published_at).to be_nil
    allow_any_instance_of(Messaging::OutboxEvent).to receive(:update!).and_call_original
    expect(publisher).to receive(:publish).with(have_attributes(event_id: event.event_id)).and_return(true)
    expect(worker.call).to eq(1)
  end
end
