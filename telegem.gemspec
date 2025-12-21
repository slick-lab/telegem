# telegem.gemspec
Gem::Specification.new do |spec|
  spec.name          = "telegem"
  
  # Read version from lib/telegem.rb
  version_file = File.read('lib/telegem.rb').match(/VERSION\s*=\s*['"]([^'"]+)['"]/)
  spec.version = version_file ? version_file[1] : "0.2.5"
  
  spec.authors       = ["Phantom"]
  spec.email         = ["ynghosted@icloud.com"]

  spec.summary       = "Modern, async Telegram Bot API for Ruby"
  spec.description   = "A Telegraf-inspired Telegram Bot framework with async I/O"
  spec.homepage      = "https://gitlab.com/ruby-telegem/telegem"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  # Include all necessary files
  spec.files         = Dir[
    "lib/**/*.rb",           # All Ruby files in lib/
    "webhook/**/*.rb",       # Webhook files (if in root)
    "README.md",
    "LICENSE.txt",
    "CHANGELOG.md",
    "*.gemspec"
  ].select { |f| File.exist?(f) }
  
  # This tells RubyGems to look in lib/ when requiring
  spec.require_paths = ["lib"]

  spec.metadata = {
    "homepage_uri" => "https://gitlab.com/ruby-telegem/telegem",
    "source_code_uri" => "https://gitlab.com/ruby-telegem/telegem",
    "changelog_uri" => "https://gitlab.com/ruby-telegem/telegem/-/blob/main/CHANGELOG.md"
  }

  spec.add_dependency "async", "~> 2.0"
  spec.add_dependency "async-http", "~> 0.60"
  spec.add_dependency "mime-types", "~> 3.4"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end