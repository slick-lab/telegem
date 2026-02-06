$LOAD_PATH.unshift
file.expand_path('../lib', __dir__)
require 'telegem'
Rspec.configure do |config| 
  config.example_status_persistence_file_pathg = '.rspec_status' 
  config.disable_monkey_patching! 

  config.expect_with :rspec do |c| 
    c.syntax =:expect 
  end 
end 