# frozen_string_literal: true

require_relative 'spec_helper'
require 'lib/api/types'
require 'lib/core/bot'
require 'lib/markup/keyboard'
require 'lib/markup/inline'

RSpec.describe Telegem do
  it 'has a version number' do
    expect(Telegem::VERSION).not_to be_nil
  end

  it 'can create a bot instance' do
    bot = Telegem.new('test_token')
    expect(bot).to be_a(Telegem::Core::Bot)
  end

  describe 'API Client' do
    let(:client) { Telegem::API::Client.new('test_token') }

    it 'initializes with a token' do
      expect(client.token).to eq('test_token')
    end

    it 'has a logger' do
      expect(client.logger).to be_a(Logger)
    end
  end

  describe 'Types' do
    describe 'BaseType' do
      let(:data) { { 'id' => 123, 'name' => 'test' } }
      let(:base) { Telegem::Types::BaseType.new(data) }

      it 'stores raw data' do
        expect(base._raw_data).to eq(data)
      end

      it 'responds to dynamic methods' do
        expect(base.id).to eq(123)
        expect(base.name).to eq('test')
      end

      it 'handles missing methods' do
        expect { base.missing }.to raise_error(NoMethodError)
      end
    end

    describe 'User' do
      let(:user_data) { { 'id' => 123, 'first_name' => 'John', 'last_name' => 'Doe' } }
      let(:user) { Telegem::Types::User.new(user_data) }

      it 'has a full name' do
        expect(user.full_name).to eq('John Doe')
      end

      it 'has a mention' do
        expect(user.mention).to eq('John')
      end
    end

    describe 'Message' do
      let(:message_data) { { 'message_id' => 1, 'text' => 'Hello', 'date' => 1640995200 } }
      let(:message) { Telegem::Types::Message.new(message_data) }

      it 'parses date' do
        expect(message.date).to be_a(Time)
      end

      it 'detects commands' do
        command_message = Telegem::Types::Message.new({ 'text' => '/start', 'entities' => [{ 'type' => 'bot_command', 'offset' => 0, 'length' => 6 }] })
        expect(command_message.command?).to be_truthy
        expect(command_message.command_name).to eq('start')
      end
    end
  end

  describe 'Bot Core' do
    let(:bot) { Telegem.new('test_token') }

    it 'has handlers' do
      expect(bot.handlers).to be_a(Hash)
      expect(bot.handlers[:message]).to be_an(Array)
    end

    it 'can register commands' do
      called = false
      bot.command('test') { |ctx| called = true }

      expect(bot.handlers[:message].length).to eq(1)
    end

    it 'has session store' do
      expect(bot.session_store).to be_a(Telegem::Session::MemoryStore)
    end
  end

  describe 'Markup' do
    it 'creates keyboards' do
      kb = Telegem.keyboard do
        row do
          button 'Test'
        end
      end
      expect(kb).to be_a(Telegem::Markup::ReplyKeyboard)
    end

    it 'creates inline keyboards' do
      kb = Telegem.inline do
        row do
          button 'Test', callback_data: 'test'
        end
      end
      expect(kb).to be_a(Telegem::Markup::InlineKeyboard)
    end
  end
end 
