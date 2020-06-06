require_relative "lib/phaedra/version"

Gem::Specification.new do |spec|
  spec.name          = "phaedra"
  spec.version       = Phaedra::VERSION
  spec.authors       = ["Jared White"]
  spec.email         = ["jared@whitefusion.io"]

  spec.summary       = %q{Write serverless Ruby functions via a REST microframework compatible with Rack or WEBrick.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/whitefusionhq/phaedra"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "~> 6.0"
  spec.add_runtime_dependency "rack", "~> 2.0"
  
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
end
