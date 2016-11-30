$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sibyl/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sibyl"
  s.version     = Sibyl::VERSION
  s.authors     = ["Simon George"]
  s.email       = ["simon@sfcgeorge.co.uk"]
  s.homepage    = ""
  s.summary     = "Sibyl is a central event log, trigger, and analysis tool."
  s.description = "Sibyl is a central event log, trigger, and analysis tool."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 5.0.0"
  s.add_dependency "pg"
  s.add_dependency "sidekiq"
end
