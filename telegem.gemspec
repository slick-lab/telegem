# telegem.gemspec
require_relative 'lib/telegem'

Gem::Specification.new do |spec|
  spec.name          = "telegem"
  spec.version       = Telegem::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your-email@example.com"]
  
  spec.summary       = "Modern, async Telegram Bot API for Ruby"
  spec.description   = "Blazing-fast Telegram Bot framework with true async/await patterns, inspired by Telegraf.js"
  spec.homepage      = "https://gitlab.com/ruby-telegem/telegem"
  spec.license       = "MIT"
  
  spec.required_ruby_version = ">= 2.7.0"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/ruby-telegem/telegem"
  spec.metadata["changelog_uri"] = "https://gitlab.com/ruby-telegem/telegem/-/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://gitlab.com/ruby-telegem/telegem/-/tree/main/docs"
  
  # Specify which files should be added to the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  # Alternative simpler file list if git isn't available
  if spec.files.empty?
    spec.files = Dir["lib/**/*.rb"] + Dir["docs/**/*"] + Dir["examples/**/*"] + %w[README.md LICENSE.txt CHANGELOG.md]
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  # Dependencies
  spec.add_dependency "httpx", "~> 0.24.0"
  
  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14.0"
end