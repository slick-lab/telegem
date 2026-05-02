# telegem.gemspec
require_relative 'lib/telegem'

Gem::Specification.new do |spec|
  spec.name          = "telegem"
  spec.version       = Telegem::VERSION
  spec.authors       = ["zendrx"]
  spec.email         = ["ynwghosted@icloud.com"]
  
  spec.summary       = "Modern, fast Telegram Bot Framework for Ruby"
  spec.description   = <<~DESC
    Telegem is a modern Telegram Bot Framework for Ruby inspired by Telegraf.js.
    Built with async-first design using async-http, featuring scenes, middleware,
    and a clean DSL. Perfect for building scalable Telegram bots.
  DESC
  
  spec.homepage      = "https://github.com/slick-lab/telegem"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  
  # Files to include
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  spec.bindir        = "bin"
  spec.executables   = ["telegem-ssl"]
  spec.require_paths = ["lib"]
  
  # Dependencies
  spec.add_dependency "securerandom", "~> 0.1"
  spec.add_dependency "async", "~> 2.35.2"
  spec.add_dependency "async-http", "~> 0.92.1"
  spec.add_dependency "pdf-reader", "~> 2.14.1"
  spec.add_dependency "docx", "~> 0.10.0"
  
  # Developmen
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  
  # Metadata
  spec.metadata = {
    "homepage_uri" => "#{spec.homepage}/-/blob/main/README.md" ,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/-/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/-/issues",
    "documentation_uri" => "https://github.com/slick-lab/telegem/tree/main/docs",
    "rubygems_mfa_required" => "false"
  }
  
  # Install message with SSL info
  spec.post_install_message = <<~MSG
    Thanks for installing Telegem #{Telegem::VERSION}!
    
    Documentation: #{spec.homepage}
    
     For SSL Webhooks:
    Run: telegem-ssl your-domain.com
    This sets up Let's Encrypt certificates automatically.

    join the official telegram group: https://t.me/r_telegem
     Happy bot building!
  MSG
end
