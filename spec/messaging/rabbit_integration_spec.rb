require "rails_helper"

RSpec.describe "RabbitMQ outbox integration" do
  before do
    skip "Set RABBITMQ_TEST_URL to an isolated test vhost" unless ENV["RABBITMQ_TEST_URL"]
    @previous_url = ENV["RABBITMQ_URL"]
    ENV["RABBITMQ_URL"] = ENV.fetch("RABBITMQ_TEST_URL")
    @connection = Bunny.new(ENV.fetch("RABBITMQ_TEST_URL"))
    @connection.start
    @channel = @connection.create_channel
    Messaging::Topology.declare(@channel)
    @publisher = Messaging::RabbitPublisher.new
  end

  after do
    @publisher&.close
    @connection.close if @connection&.open?
    ENV["RABBITMQ_URL"] = @previous_url if @connection
  end

  def receive_event(queue_name, event_id)
    queue = @channel.queue(queue_name, passive: true)
    100.times do
      info, properties, body = queue.pop(manual_ack: true)
      return unless info
      decoded = JSON.parse(body)
      @channel.ack(info.delivery_tag)
      return [properties, decoded] if decoded.fetch("event_id") == event_id
    end
    nil
  end

  it "routes a persisted reservation to triagem and read model with the same event_id" do
    event = Messaging::Outbox.record!(event_type: "consulta.reserva_criada", consulta_id: "42", data: { sala: "Sala 1" })
    Messaging::PublishPending.new(publisher: @publisher).call
    expect(event.reload.published_at).to be_present
    %w[psiline.triagem psiline.read_model].each do |queue|
      properties, body = receive_event(queue, event.event_id)
      expect(properties.message_id).to eq(event.event_id)
      expect(properties.delivery_mode).to eq(2)
      expect(body).to include("consulta_id" => "42", "version" => 1)
    end
  end

  it "routes triagem outcomes to agendamento" do
    %w[triagem.aprovada triagem.reprovada].each do |type|
      event = Messaging::Outbox.record!(event_type: type, consulta_id: "42", data: {})
      @publisher.publish(event)
      expect(receive_event("psiline.agendamento", event.event_id)).to be_present
    end
  end

  it "detects a real mandatory return for a routing key without bindings" do
    event = Messaging::Outbox.record!(event_type: "triagem.aprovada", consulta_id: "42", data: {})
    allow(event).to receive(:event_type).and_return("unknown.event")
    expect { @publisher.publish(event) }.to raise_error(Messaging::RabbitPublisher::Unroutable)
  end

  it "dead letters a rejected message without requeue" do
    event = Messaging::Outbox.record!(event_type: "consulta.reserva_criada", consulta_id: "42", data: {})
    @publisher.publish(event)
    queue = @channel.queue("psiline.triagem", passive: true)
    100.times do
      info, _properties, body = queue.pop(manual_ack: true)
      break unless info
      if JSON.parse(body).fetch("event_id") == event.event_id
        @channel.reject(info.delivery_tag, false)
        break
      end
      @channel.ack(info.delivery_tag)
    end
    received = nil
    Timeout.timeout(5) do
      until received
        received = receive_event("psiline.triagem.dead", event.event_id)
        sleep 0.02 unless received
      end
    end
    expect(received.last.fetch("event_id")).to eq(event.event_id)
  end
end
