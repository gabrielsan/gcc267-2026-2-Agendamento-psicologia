require "rails_helper"

RSpec.describe Messaging::RabbitPublisher do
  let(:connection) { double("connection", open?: true, close: nil, start: true, create_channel: channel) }
  let(:channel) { double("channel", confirm_select: true, wait_for_confirms: true) }
  let(:exchange) { double("exchange", publish: true, on_return: true) }
  let(:event) { Messaging::Outbox.record!(event_type: "triagem.aprovada", consulta_id: "42", data: {}) }
  subject(:publisher) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("RABBITMQ_URL").and_return("amqp://test")
    allow(Bunny).to receive(:new).and_return(connection)
    allow(Messaging::Topology).to receive(:declare).with(channel).and_return(exchange)
  end

  it "uses persistent mandatory publishing and publisher confirms" do
    expect(channel).to receive(:confirm_select)
    expect(exchange).to receive(:publish).with(JSON.generate(event.envelope), hash_including(
      persistent: true, mandatory: true, message_id: event.event_id, routing_key: event.event_type))
    expect(publisher.publish(event)).to be(true)
  end

  it "rejects negative confirmations" do
    allow(channel).to receive(:wait_for_confirms).and_return(false)
    expect { publisher.publish(event) }.to raise_error(described_class::NotConfirmed)
    expect(connection).to have_received(:close)
  end

  it "rejects unroutable messages even if the exchange accepted them" do
    callback = nil
    allow(exchange).to receive(:on_return) { |&block| callback = block }
    allow(exchange).to receive(:publish) { callback.call(nil, nil, nil) }
    expect { publisher.publish(event) }.to raise_error(described_class::Unroutable)
  end
end
