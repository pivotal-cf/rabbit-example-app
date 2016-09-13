require_relative "../lib/store"

RSpec.describe 'Store' do
  subject(:store) { RabbitExample::Store.new }

  let(:mock_channel) { double("channel") }
  let(:env_queue_name) { nil }
  let(:env_queue_opts) { nil }
  let(:mock_connection) { instance_double(Bunny::Session) }
  let(:messages) { ["message"] }

  before(:each) do
    allow(ENV).to receive(:[]).with('VCAP_SERVICES').and_return(
      <<-JSON
      {
        "rabbitmq-dev3": [
         {
          "credentials": {
           "protocols": {
            "amqp": {
             "uris": [
              "amqp://admin:rabbitmq@rabbit-land.me/"
             ]
            }
           }
          },
          "tags": [
           "rabbitmq"
          ]
         }
        ]
       }
      JSON
    )

    allow(ENV).to receive(:[]).with('QUEUE_NAME').and_return(env_queue_name)
    allow(ENV).to receive(:[]).with('QUEUE_OPTS').and_return(env_queue_opts)

    mock_queue = double("queue")

    allow(Bunny).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
    allow(mock_connection).to receive(:start)
    allow(mock_connection).to receive(:close)
    allow(mock_channel).to receive(:queue).and_return(mock_queue)
    allow(mock_queue).to receive(:publish)
    allow(mock_queue).to receive(:pop).and_return(messages)
  end

  describe "#write" do
    it "closes connection" do
      store.write("message")

      expect(mock_connection).to have_received(:close)
    end
  end

  describe "#read" do
    it "closes connection" do
      store.read

      expect(mock_connection).to have_received(:close)
    end
  end

  context "when the queue is not set" do
    let(:env_queue_name) { nil }

    it "publishes a message to the default queue" do
      store.write("message")

      expect(mock_channel).to have_received(:queue).with('storeq', durable: true)
    end
  end

  context "when the queue is set as an environment variable" do
    let(:env_queue_name) { "env-queue" }

    it "publishes a message to QUEUE_NAME" do
      store.write("message")

      expect(mock_channel).to have_received(:queue).with('env-queue', durable: true)
    end
  end

  context "when the queue options are set as an environment variable" do
    let(:env_queue_opts) { '{"durable":false}' }

    it "publishes a message to the default non-durable queue" do
      store.write("message")

      expect(mock_channel).to have_received(:queue).with('storeq', durable: false)
    end
  end

  context "when the store is initialised with a queue name" do
    subject(:store) { RabbitExample::Store.new "user-queue" }

    context("with QUEUE_NAME set") do
      let(:env_queue_name) { "env-queue" }

      it "publishes a message to the specified queue" do
        store.write("message")

        expect(mock_channel).to have_received(:queue).with('user-queue', durable: true)
      end
    end

    context("without QUEUE_NAME") do
      let(:env_queue_name) { nil }

      it "publishes a message to the specified queue" do
        store.write("message")

        expect(mock_channel).to have_received(:queue).with('user-queue', durable: true)
      end
    end
  end
end
