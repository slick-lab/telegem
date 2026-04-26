# Testing

Comprehensive testing ensures your Telegem bot works correctly and handles edge cases properly.

## Test Setup

### RSpec Configuration

```ruby
# spec/spec_helper.rb
require 'telegem'
require 'rspec'
require 'webmock/rspec'

# Disable real HTTP requests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    WebMock.reset!
  end
end

# Test helpers
module TestHelpers
  def create_mock_update(type, **attrs)
    # Create mock Telegram update
  end

  def simulate_message(bot, text, from: nil, chat: nil)
    # Simulate incoming message
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
```

### Test Bot Factory

```ruby
# spec/support/bot_factory.rb
module BotFactory
  def create_test_bot(token: 'test_token', **options)
    bot = Telegem.new(token: token, **options)

    # Mock API calls
    allow(bot.api).to receive(:call).and_return({'ok' => true})

    # Use memory store for tests
    bot.session_store = Telegem::Session::MemoryStore.new

    bot
  end
end
```

## Unit Testing

### Handler Testing

```ruby
# spec/bot_handlers_spec.rb
RSpec.describe 'Bot Handlers' do
  let(:bot) { create_test_bot }

  describe '/start command' do
    it 'responds with welcome message' do
      expect(bot.api).to receive(:call).with('sendMessage', hash_including(text: /Welcome/))

      simulate_message(bot, '/start')
    end
  end

  describe 'hears pattern' do
    it 'matches hello messages' do
      expect(bot.api).to receive(:call).with('sendMessage', hash_including(text: 'Hi there!'))

      simulate_message(bot, 'hello world')
    end
  end
end
```

### Context Testing

```ruby
# spec/context_spec.rb
RSpec.describe Telegem::Context do
  let(:bot) { create_test_bot }
  let(:update) { create_mock_update(:message, text: 'test') }
  let(:ctx) { Telegem::Context.new(bot, update) }

  describe '#reply' do
    it 'sends message to chat' do
      expect(bot.api).to receive(:call).with('sendMessage',
        chat_id: ctx.chat.id,
        text: 'Hello'
      )

      ctx.reply('Hello')
    end
  end

  describe '#session' do
    it 'stores and retrieves data' do
      ctx.session[:user_id] = 123
      expect(ctx.session[:user_id]).to eq(123)
    end
  end
end
```

### API Client Testing

```ruby
# spec/api_client_spec.rb
RSpec.describe Telegem::API::Client do
  let(:client) { Telegem::API::Client.new('test_token') }

  describe '#call' do
    it 'makes successful API call' do
      stub_request(:post, /api\.telegram\.org/)
        .to_return(body: {'ok' => true, 'result' => {}}.to_json)

      result = client.call('getMe')
      expect(result['ok']).to be true
    end

    it 'handles API errors' do
      stub_request(:post, /api\.telegram\.org/)
        .to_return(status: 400, body: {'ok' => false, 'description' => 'Bad Request'}.to_json)

      expect { client.call('invalidMethod') }.to raise_error(Telegem::API::APIError)
    end
  end
end
```

## Integration Testing

### Full Bot Testing

```ruby
# spec/integration/bot_integration_spec.rb
RSpec.describe 'Bot Integration' do
  let(:bot) { create_test_bot }

  before do
    bot.command('echo') do |ctx|
      ctx.reply(ctx.text)
    end

    bot.hears(/^hello/) do |ctx|
      ctx.reply('Hi there!')
    end
  end

  it 'handles command' do
    simulate_message(bot, '/echo test message')

    expect(last_api_call).to include(
      method: 'sendMessage',
      text: 'test message'
    )
  end

  it 'handles hears pattern' do
    simulate_message(bot, 'hello world')

    expect(last_api_call).to include(
      method: 'sendMessage',
      text: 'Hi there!'
    )
  end
end
```

### Middleware Testing

```ruby
# spec/middleware_spec.rb
RSpec.describe 'Middleware Chain' do
  let(:bot) { create_test_bot }

  it 'executes middleware in order' do
    execution_order = []

    bot.use(lambda do |ctx, next_middleware|
      execution_order << :first
      next_middleware.call(ctx)
      execution_order << :first_after
    end)

    bot.use(lambda do |ctx, next_middleware|
      execution_order << :second
      next_middleware.call(ctx)
      execution_order << :second_after
    end)

    bot.command('test') do |ctx|
      execution_order << :handler
      ctx.reply('done')
    end

    simulate_message(bot, '/test')

    expect(execution_order).to eq([
      :first, :second, :handler, :second_after, :first_after
    ])
  end
end
```

## Scene Testing

### Scene Flow Testing

```ruby
# spec/scenes_spec.rb
RSpec.describe 'User Scenes' do
  let(:bot) { create_test_bot }

  before do
    bot.scene('registration') do |scene|
      scene.step('name') do |ctx|
        ctx.reply('Enter your name:')
        ctx.session[:name] = ctx.text
        scene.next_step
      end

      scene.step('age') do |ctx|
        ctx.reply('Enter your age:')
        ctx.session[:age] = ctx.text.to_i
        scene.complete
      end
    end
  end

  it 'completes registration scene' do
    # Start scene
    simulate_message(bot, '/register')

    # Enter name
    simulate_message(bot, 'John Doe')

    # Enter age
    simulate_message(bot, '25')

    # Verify completion
    expect(user_session[:name]).to eq('John Doe')
    expect(user_session[:age]).to eq(25)
    expect(user_session[:current_scene]).to be_nil
  end
end
```

## Plugin Testing

### FileExtract Plugin Testing

```ruby
# spec/plugins/file_extract_spec.rb
RSpec.describe Telegem::Plugins::FileExtract do
  let(:bot) { create_test_bot }
  let(:file_id) { 'test_file_id' }

  describe '#extract' do
    it 'extracts PDF content' do
      # Mock file download
      allow(bot.api).to receive(:download_file).and_return(pdf_content)

      extractor = Telegem::Plugins::FileExtract.new(bot, file_id)
      result = extractor.extract

      expect(result[:success]).to be true
      expect(result[:type]).to eq(:pdf)
      expect(result[:content]).to include('extracted text')
    end

    it 'handles extraction errors' do
      allow(bot.api).to receive(:download_file).and_raise(StandardError)

      extractor = Telegem::Plugins::FileExtract.new(bot, file_id)
      result = extractor.extract

      expect(result[:success]).to be false
      expect(result[:error]).to be_present
    end
  end
end
```

## Mock Data

### Mock Update Creation

```ruby
# spec/support/mock_updates.rb
def create_mock_update(type, **attrs)
  base_update = {
    update_id: rand(1000000),
    message: nil,
    edited_message: nil,
    channel_post: nil,
    edited_channel_post: nil,
    inline_query: nil,
    chosen_inline_result: nil,
    callback_query: nil,
    shipping_query: nil,
    pre_checkout_query: nil
  }

  case type
  when :message
    base_update[:message] = create_mock_message(**attrs)
  when :callback_query
    base_update[:callback_query] = create_mock_callback_query(**attrs)
  end

  base_update
end

def create_mock_message(**attrs)
  {
    message_id: rand(100000),
    from: create_mock_user,
    chat: create_mock_chat,
    date: Time.now.to_i,
    text: attrs[:text] || 'test message',
    entities: attrs[:entities] || []
  }.merge(attrs)
end

def create_mock_user(**attrs)
  {
    id: rand(1000000000),
    is_bot: false,
    first_name: 'Test',
    last_name: 'User',
    username: 'testuser'
  }.merge(attrs)
end

def create_mock_chat(**attrs)
  {
    id: rand(1000000000),
    type: 'private',
    title: nil,
    username: nil,
    first_name: 'Test',
    last_name: 'User'
  }.merge(attrs)
end
```

### API Response Stubbing

```ruby
# spec/support/api_stubs.rb
def stub_telegram_api(method, response = {}, status = 200)
  stub_request(:post, "https://api.telegram.org/bot#{@token}/#{method}")
    .to_return(
      status: status,
      body: response.to_json,
      headers: {'Content-Type' => 'application/json'}
    )
end

def stub_successful_send_message(text = nil)
  stub_telegram_api('sendMessage', {
    'ok' => true,
    'result' => {
      'message_id' => rand(100000),
      'from' => {'id' => 123456, 'is_bot' => true, 'first_name' => 'TestBot'},
      'chat' => {'id' => 789, 'type' => 'private'},
      'date' => Time.now.to_i,
      'text' => text || 'Test response'
    }
  })
end
```

## Test Helpers

### Message Simulation

```ruby
# spec/support/message_simulation.rb
def simulate_message(bot, text, from: nil, chat: nil, **attrs)
  update = create_mock_update(:message,
    text: text,
    from: from || create_mock_user,
    chat: chat || create_mock_chat,
    **attrs
  )

  # Process update through bot
  bot.process_update(update)
end

def simulate_callback(bot, data, from: nil, message: nil, **attrs)
  callback_query = create_mock_callback_query(
    data: data,
    from: from || create_mock_user,
    message: message || create_mock_message,
    **attrs
  )

  update = create_mock_update(:callback_query, callback_query: callback_query)
  bot.process_update(update)
end

def last_api_call
  WebMock::RequestRegistry.instance.requested_signatures.last
end
```

## Asynchronous Testing

### Async Handler Testing

```ruby
# spec/async_handlers_spec.rb
RSpec.describe 'Async Handlers' do
  let(:bot) { create_test_bot }

  it 'handles async operations' do
    responses = []

    bot.command('async') do |ctx|
      Async do
        sleep 0.1
        responses << 'async_done'
        ctx.reply('Async complete')
      end
      responses << 'handler_done'
    end

    simulate_message(bot, '/async')

    # Wait for async operation
    sleep 0.2

    expect(responses).to eq(['handler_done', 'async_done'])
    expect(last_api_call[:body]).to include('Async complete')
  end
end
```

## Performance Testing

### Load Testing

```ruby
# spec/performance/load_spec.rb
RSpec.describe 'Bot Performance' do
  let(:bot) { create_test_bot }

  it 'handles multiple concurrent requests' do
    bot.command('test') do |ctx|
      ctx.reply("Response #{ctx.message.message_id}")
    end

    # Simulate concurrent requests
    threads = 10.times.map do |i|
      Thread.new do
        simulate_message(bot, "/test #{i}")
      end
    end

    threads.each(&:join)

    # Verify all requests processed
    expect(WebMock::RequestRegistry.instance.requested_signatures.size).to eq(10)
  end
end
```

### Benchmark Testing

```ruby
# spec/performance/benchmark_spec.rb
require 'benchmark'

RSpec.describe 'Bot Benchmarks' do
  let(:bot) { create_test_bot }

  it 'processes messages quickly' do
    bot.command('bench') do |ctx|
      # Simple response
      ctx.reply('OK')
    end

    time = Benchmark.realtime do
      100.times { simulate_message(bot, '/bench') }
    end

    avg_time = time / 100
    expect(avg_time).to be < 0.01 # Less than 10ms per message
  end
end
```

## Continuous Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.1
        bundler-cache: true

    - name: Run tests
      run: bundle exec rspec

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/coverage.xml
```

### Code Coverage

```ruby
# spec/spec_helper.rb
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 90
end
```

## Test Organization

### Directory Structure

```
spec/
├── spec_helper.rb
├── support/
│   ├── bot_factory.rb
│   ├── mock_updates.rb
│   ├── api_stubs.rb
│   └── message_simulation.rb
├── unit/
│   ├── api_client_spec.rb
│   ├── context_spec.rb
│   └── middleware_spec.rb
├── integration/
│   ├── bot_integration_spec.rb
│   └── scenes_spec.rb
├── plugins/
│   ├── file_extract_spec.rb
│   └── translate_spec.rb
├── performance/
│   ├── load_spec.rb
│   └── benchmark_spec.rb
└── features/
    └── end_to_end_spec.rb
```

### Test Naming Conventions

```ruby
# Good
describe '#reply' do
  context 'when chat is private' do
    it 'sends message to user' do
      # test
    end
  end
end

# Bad
describe 'reply method' do
  it 'test reply' do
    # test
  end
end
```

## Best Practices

1. **Test behavior, not implementation**
2. **Use descriptive test names**
3. **Keep tests isolated and independent**
4. **Mock external dependencies**
5. **Test edge cases and error conditions**
6. **Use factories for test data**
7. **Maintain high code coverage**
8. **Run tests in CI/CD pipeline**
9. **Test async operations properly**
10. **Document complex test scenarios**

Comprehensive testing ensures your bot is reliable, maintainable, and ready for production deployment.</content>
<parameter name="filePath">/home/slick/telegem/docs/testing.md