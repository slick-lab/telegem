# telegem.gemspec - FIXED VERSION
Gem::Specification.new do |spec|
  spec.name          = "telegem"
  
  # FIX 1: Read version from file WITHOUT requiring
  version_file = File.read('version.rb').match(/VERSION\s*=\s*['"]([^'"]+)['"]/)
  spec.version = version_file ? version_file[1] : "0.1.1."
  
  spec.authors       = ["Phantom"]
  spec.email         = ["ynghosted@icloud.com"]

  spec.summary       = "Modern, async Telegram Bot API for Ruby"
  spec.description   = "A Telegraf-inspired Telegram Bot framework with async I/O"
  spec.homepage      = "https://gitlab.com/ruby-telegem/telegem"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  # FIX 2: Include ALL Ruby files in root AND subdirectories
  spec.files         = Dir[
    "*.rb",           # telegem.rb, version.rb at root
    "lib/**/*.rb",    # All Ruby files in lib/
    "webhook/**/*.rb", # All Ruby files in webhook/
    "README.md",
    "LICENSE.txt"
  ]
  
  # FIX 3: Tell Ruby to look in current directory for telegem.rb
  spec.require_paths = ["."]

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