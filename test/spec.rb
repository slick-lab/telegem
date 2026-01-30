require_relative 'spec_helper'

RSpec.describe Telegem do
  it 'has a version' do
    expect(Telegem::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end

RSpec.describe Telegem::Core::Bot do
  let(:token) { 'test_token' }
  let(:bot) { Telegem::Core::Bot.new(token) }
  end
  it 'creates bot with token' do
    expect(bot.token).to eq(token)
  end

  it 'has api client' do
    expect(bot.api).to be_a(Telegem::API::Client)
  end

  it 'can register command' do
    bot.command('start') { |ctx| }
    expect(bot.handlers[:message].size).to eq(1)
  end

  it 'can register scene' do
    bot.scene(:welcome) { |s| s.step(:start) { |c| } }
    expect(bot.scenes[:welcome]).to be_a(Telegem::Core::Scene)
  end


RSpec.describe Telegem::API::Client do
  let(:client) { Telegem::API::Client.new('fake_token') }

  it 'creates client' do
    expect(client.token).to eq('fake_token')
  end

  it 'has http client' do
    expect(client.http).to be_a(HTTPX::Session)
  end
end

RSpec.describe Telegem::Types::Update do
  let(:data) { { 'update_id' => 123, 'message' => { 'text' => 'hi' } } }
  let(:update) { described_class.new(data) }

  it 'parses update_id' do
    expect(update.update_id).to eq(123)
  end

  it 'creates message object' do
    expect(update.message).to be_a(Telegem::Types::Message)
    expect(update.message.text).to eq('hi')
  end
end

RSpec.describe Telegem::Session::MemoryStore do
  let(:store) { described_class.new }

  it 'stores and retrieves values' do
    store.set('key', 'value')
    expect(store.get('key')).to eq('value')
  end

  it 'expires values' do
    store.set('temp', 'data', ttl: 1)
    expect(store.get('temp')).to eq('data')
    sleep 1.1
    expect(store.get('temp')).to be_nil
  end
end

RSpec.describe Telegem::Markup::Keyboard do
  it 'builds keyboard' do
    kb = Telegem.keyboard do |k|
      k.button "Yes"
      k.button "No"
    end

    expect(kb.to_h[:keyboard]).to eq([[{ text: "Yes" }, { text: "No" }]])
  end
end