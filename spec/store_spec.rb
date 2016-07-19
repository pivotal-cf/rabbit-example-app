require_relative "../lib/store"

RSpec.describe 'Store' do
  let(:mock_channel) { double("channel") }

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

    mock_connection = double("connection")
    mock_queue = double("queue")

    allow(Bunny).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
    allow(mock_connection).to receive(:start)
    allow(mock_channel).to receive(:queue).and_return(mock_queue)
    allow(mock_queue).to receive(:publish)
  end

  context "when the queue is not set" do
    subject(:store) { RabbitExample::Store.new }
    before(:each) do
      allow(ENV).to receive(:[]).with('QUEUE_NAME').and_return(nil)
    end

    it "publishes a message to the default queue" do
      store.write("message")

      expect(mock_channel).to have_received(:queue).with('storeq', durable: true)
    end
  end

  context "when the queue is set as an environment variable" do
    subject(:store) { RabbitExample::Store.new }
    before(:each) do
      allow(ENV).to receive(:[]).with('QUEUE_NAME').and_return("env-queue")
    end

    it "publishes a message to QUEUE_NAME" do
      store.write("message")

      expect(mock_channel).to have_received(:queue).with('env-queue', durable: true)
    end
  end

  context "when the store is initialised with a queue name" do
    subject(:store) { RabbitExample::Store.new "user-queue" }

    context("with QUEUE_NAME set") do
      before(:each) do
        allow(ENV).to receive(:[]).with('QUEUE_NAME').and_return("env-queue")
      end

      it "publishes a message to the specified queue" do
        store.write("message")

        expect(mock_channel).to have_received(:queue).with('user-queue', durable: true)
      end
    end

    context("without QUEUE_NAME") do
      before(:each) do
        allow(ENV).to receive(:[]).with('QUEUE_NAME').and_return(nil)
      end

      it "publishes a message to the specified queue" do
        store.write("message")

        expect(mock_channel).to have_received(:queue).with('user-queue', durable: true)
      end
    end
  end
end
