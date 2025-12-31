# telegem.gemspec
require_relative 'lib/telegem'

Gem::Specification.new do |spec|
  spec.name          = "telegem"
  spec.version       = Telegem::VERSION
  spec.authors       = ["sick_phantom"]
  spec.email         = ["ynwghosted@icloud.com"]
  
  spec.summary       = "Modern, fast Telegram Bot Framework for Ruby"
  spec.description   = <<~DESC
    Telegem is a modern Telegram Bot Framework for Ruby inspired by Telegraf.js.
    Built with async-first design using HTTPX, featuring scenes, middleware,
    and a clean DSL. Perfect for building scalable Telegram bots.
  DESC
  
  spec.homepage      = "https://gitlab.com/ruby-telegem/telegem"
  spec.license       = "MIT"
  
  spec.required_ruby_version = ">= 3.1.0"
  
  # Specify which files should be added to the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  # Runtime dependencies
  spec.add_dependency "httpx", "~> 0.20"
  spec.add_dependency "concurrent-ruby", "~> 1.2"
  spec.add_dependency "rack", ">= 2.0", "< 4.0"
  spec.add_dependency "puma", ">= 5.0", "< 7.0"
  
  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "rubocop", "~> 1.50"
  
  # Metadata for RubyGems.org
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/-/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/-/issues",
    "documentation_uri" => "https://gitlab.com/ruby-telegem/telegem/-/tree/main/docs-src?ref_type=heads"
    "rubygems_mfa_required" => "false"
  }
  
  # Post-install message
  spec.post_install_message = <<~MSG
    Thanks for installing Telegem #{Telegem::VERSION}!
    Documentation: #{spec.homepage}
    Happy bot building! 🤖
  MSG
end