require_relative 'spec_helper'
require 'json'

RSpec.describe Telegem::Webhook::Server do
  let(:bot) { Telegem.new('test_token') }
  let(:port) { 3000 }
  let(:host) { '0.0.0.0' }

  describe 'initialization' do
    it 'creates a webhook server with default settings' do
      server = Telegem::Webhook::Server.new(bot, port: port)
      expect(server).to be_a(Telegem::Webhook::Server)
      expect(server.port).to eq(port)
      expect(server.host).to eq(host)
    end

    it 'has a secret token' do
      server = Telegem::Webhook::Server.new(bot, port: port)
      expect(server.secret_token).not_to be_nil
      expect(server.secret_token.length).to be > 0
    end

    it 'uses environment token if provided' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WEBHOOK_SECRET_TOKEN').and_return('custom_token')
      
      server = Telegem::Webhook::Server.new(bot, port: port)
      expect(server.secret_token).to eq('custom_token')
    end

    it 'accepts custom secret token' do
      custom_token = 'my_secure_token'
      server = Telegem::Webhook::Server.new(bot, port: port, secret_token: custom_token)
      expect(server.secret_token).to eq(custom_token)
    end

    it 'defaults to port 3000' do
      server = Telegem::Webhook::Server.new(bot)
      expect(server.port).to eq(3000)
    end

    it 'is not running initially' do
      server = Telegem::Webhook::Server.new(bot, port: port)
      expect(server.running).to be_falsy
    end
  end

  describe 'SSL configuration' do
    it 'detects cloud SSL mode' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TELEGEM_WEBHOOK_URL').and_return('https://example.com')
      
      server = Telegem::Webhook::Server.new(bot, port: port)
      expect(server.ssl_mode).to eq(:cloud)
    end

    it 'detects no SSL when no HTTPS' do
      server = Telegem::Webhook::Server.new(bot, port: port, ssl: false)
      expect(server.ssl_mode).to eq(:none)
    end

    it 'supports manual SSL configuration' do
      ssl_context = double('ssl_context')
      server = Telegem::Webhook::Server.new(
        bot, 
        port: port,
        ssl: { cert_path: '/path/to/cert', key_path: '/path/to/key' }
      )
      expect(server.ssl_mode).to eq(:manual)
    end
  end

  describe 'webhook URL generation' do
    it 'generates HTTP URL in none mode' do
      server = Telegem::Webhook::Server.new(bot, port: port, ssl: false)
      server.instance_variable_set(:@secret_token, 'test_token_123')
      
      url = server.webhook_url
      expect(url).to include('0.0.0.0')
      expect(url).to include('3000')
      expect(url).to include('test_token_123')
    end

    it 'generates HTTPS URL in cloud mode' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TELEGEM_WEBHOOK_URL').and_return('https://bot.example.com')
      
      server = Telegem::Webhook::Server.new(bot, port: port)
      server.instance_variable_set(:@secret_token, 'test_token')
      
      url = server.webhook_url
      expect(url).to include('https://bot.example.com')
      expect(url).to include('test_token')
    end
  end

  describe 'request handling' do
    let(:server) { Telegem::Webhook::Server.new(bot, port: port, secret_token: 'test_secret') }

    describe 'webhook request' do
      it 'accepts valid webhook requests' do
        update_data = {
          update_id: 123,
          message: {
            message_id: 1,
            date: Time.now.to_i,
            chat: { id: 456, type: 'private' },
            from: { id: 789, first_name: 'Test' },
            text: 'Hello'
          }
        }

        request = double('request')
        allow(request).to receive(:post?).and_return(true)
        allow(request).to receive(:path).and_return('/test_secret')
        allow(request).to receive(:headers).and_return({
          'X-Telegram-Bot-Api-Secret-Token' => 'test_secret'
        })
        
        body = double('body')
        allow(body).to receive(:read).and_return(update_data.to_json)
        allow(request).to receive(:body).and_return(body)

        expect(bot).to receive(:process).with(update_data)

        response = server.handle_request(request)
        expect(response[0]).to eq(200)
        expect(response[2][0]).to eq('OK')
      end

      it 'rejects requests without secret token header' do
        request = double('request')
        allow(request).to receive(:post?).and_return(true)
        allow(request).to receive(:path).and_return('/test_secret')
        allow(request).to receive(:headers).and_return({})

        response = server.handle_request(request)
        expect(response[0]).to eq(403)
      end

      it 'rejects requests with wrong secret token' do
        request = double('request')
        allow(request).to receive(:post?).and_return(true)
        allow(request).to receive(:path).and_return('/test_secret')
        allow(request).to receive(:headers).and_return({
          'X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret'
        })

        response = server.handle_request(request)
        expect(response[0]).to eq(403)
      end

      it 'rejects non-POST requests' do
        request = double('request')
        allow(request).to receive(:post?).and_return(false)
        allow(request).to receive(:path).and_return('/test_secret')

        response = server.handle_request(request)
        expect(response[0]).to eq(405)
      end

      it 'handles JSON parsing errors' do
        request = double('request')
        allow(request).to receive(:post?).and_return(true)
        allow(request).to receive(:path).and_return('/test_secret')
        allow(request).to receive(:headers).and_return({
          'X-Telegram-Bot-Api-Secret-Token' => 'test_secret'
        })
        
        body = double('body')
        allow(body).to receive(:read).and_return('invalid json {')
        allow(request).to receive(:body).and_return(body)

        response = server.handle_request(request)
        expect(response[0]).to eq(400)
      end
    end

    describe 'health endpoint' do
      it 'responds to /health endpoint' do
        request = double('request')
        allow(request).to receive(:path).and_return('/health')

        response = server.handle_request(request)
        expect(response[0]).to eq(200)
        
        body = response[2][0]
        json = JSON.parse(body)
        expect(json['status']).to eq('ok')
        expect(json['ssl']).to be_falsy
      end

      it 'responds to /healthz endpoint' do
        request = double('request')
        allow(request).to receive(:path).and_return('/healthz')

        response = server.handle_request(request)
        expect(response[0]).to eq(200)
        
        body = response[2][0]
        json = JSON.parse(body)
        expect(json['status']).to eq('ok')
      end
    end

    describe 'unknown routes' do
      it 'returns 404 for unknown routes' do
        request = double('request')
        allow(request).to receive(:path).and_return('/unknown')

        response = server.handle_request(request)
        expect(response[0]).to eq(404)
        expect(response[2][0]).to eq('Not Found')
      end
    end
  end

  describe 'webhook lifecycle' do
    let(:server) { Telegem::Webhook::Server.new(bot, port: port) }

    it 'can check running status' do
      expect(server.running?).to be_falsy
    end

    it 'has a stop method' do
      expect(server).to respond_to(:stop)
    end
  end

  describe 'webhook methods' do
    let(:server) { Telegem::Webhook::Server.new(bot, port: port) }

    it 'has a set_webhook method' do
      expect(server).to respond_to(:set_webhook)
    end

    it 'has a delete_webhook method' do
      expect(server).to respond_to(:delete_webhook)
    end

    it 'has a get_webhook_info method' do
      expect(server).to respond_to(:get_webhook_info)
    end
  end

  describe 'response format' do
    let(:server) { Telegem::Webhook::Server.new(bot, port: port) }

    it 'returns proper Rack response format' do
      request = double('request')
      allow(request).to receive(:path).and_return('/unknown')

      response = server.handle_request(request)
      
      expect(response).to be_an(Array)
      expect(response.length).to eq(3)
      expect(response[0]).to be_an(Integer) # status code
      expect(response[1]).to be_a(Hash)     # headers
      expect(response[2]).to be_an(Array)   # body
    end

    it 'returns string body elements' do
      request = double('request')
      allow(request).to receive(:path).and_return('/health')

      response = server.handle_request(request)
      
      expect(response[2][0]).to be_a(String)
    end
  end

  describe 'integration tests' do
    let(:server) { Telegem::Webhook::Server.new(bot, port: port, secret_token: 'webhook_secret') }

    it 'processes a complete update flow' do
      update_data = {
        update_id: 999,
        message: {
          message_id: 100,
          date: Time.now.to_i,
          chat: { id: 1001, type: 'private' },
          from: { id: 2001, first_name: 'Alice', is_bot: false },
          text: '/start'
        }
      }

      request = double('request')
      allow(request).to receive(:post?).and_return(true)
      allow(request).to receive(:path).and_return('/webhook_secret')
      allow(request).to receive(:headers).and_return({
        'X-Telegram-Bot-Api-Secret-Token' => 'webhook_secret'
      })
      
      body = double('body')
      allow(body).to receive(:read).and_return(update_data.to_json)
      allow(request).to receive(:body).and_return(body)

      expect(bot).to receive(:process).with(update_data)

      response = server.handle_request(request)

      expect(response[0]).to eq(200)
      expect(response[1]).to be_a(Hash)
      expect(response[2]).to be_an(Array)
      expect(response[2][0]).to eq('OK')
    end

    it 'handles multiple updates sequentially' do
      2.times do |i|
        update_data = {
          update_id: 1000 + i,
          message: {
            message_id: 10 + i,
            date: Time.now.to_i,
            chat: { id: 456, type: 'private' },
            from: { id: 789, first_name: 'Test' },
            text: "Message #{i}"
          }
        }

        request = double('request')
        allow(request).to receive(:post?).and_return(true)
        allow(request).to receive(:path).and_return('/webhook_secret')
        allow(request).to receive(:headers).and_return({
          'X-Telegram-Bot-Api-Secret-Token' => 'webhook_secret'
        })
        
        body = double('body')
        allow(body).to receive(:read).and_return(update_data.to_json)
        allow(request).to receive(:body).and_return(body)

        expect(bot).to receive(:process).with(update_data)

        response = server.handle_request(request)
        expect(response[0]).to eq(200)
      end
    end
  end
end
