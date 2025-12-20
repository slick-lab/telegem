require_relative 'version'

Gem::Specification.new do |spec|
  spec.name          = "telegem"
  spec.version       = Telegem::VERSION
  spec.authors       = ["Phantom"]
  spec.email         = ["ynghosted@icloud.com"]

  spec.summary       = "Modern, async Telegram Bot API for Ruby"
  spec.description   = "A Telegraf-inspired Telegram Bot framework with async I/O"
  spec.homepage      = "https://gitlab.com/ruby-telegem/telegem"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*", "telegem.rb", "version.rb", "README.md", "LICENSE.txt", "webhook/*"]
  spec.require_paths = ["lib", "webhook"]

  spec.add_dependency "async", "~> 2.0"
  spec.add_dependency "async-http", "~> 0.60"
  spec.add_dependency "mime-types", "~> 3.4"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end