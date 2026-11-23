require "rails_helper"

RSpec.describe Messaging::Outbox do
  def record
    described_class.record!(event_type: "consulta.reserva_criada", consulta_id: "42", data: { sala: "Sala 1" })
  end

  it "stores a versioned envelope with a stable event_id" do
    event = record
    expect(event.reload.envelope).to include(
      event_id: event.event_id, consulta_id: "42", version: 1,
      event_type: "consulta.reserva_criada", data: { "sala" => "Sala 1" })
    expect(event.event_id).to match(/\A[0-9a-f-]{36}\z/)
    expect(event.published_at).to be_nil
  end

  it "rolls back the event with the domain transaction" do
    expect {
      Messaging::OutboxEvent.transaction(requires_new: true) do
        record
        raise ActiveRecord::Rollback
      end
    }.not_to change(Messaging::OutboxEvent, :count)
  end

  it "rejects invalid event types and non-object data" do
    expect {
      described_class.record!(event_type: "unknown", consulta_id: "42", data: [])
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "requires an existing domain transaction" do
    allow(Messaging::OutboxEvent.connection).to receive(:transaction_open?).and_return(false)
    expect { record }.to raise_error(ArgumentError, /domain transaction/)
  end

  it "rejects duplicate event_ids in the database" do
    event = record
    expect {
      Messaging::OutboxEvent.transaction(requires_new: true) do
        described_class.record!(event_type: event.event_type, consulta_id: "42", data: {}, event_id: event.event_id)
      end
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
