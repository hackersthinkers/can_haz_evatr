
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "can_haz_evatr/version"

Gem::Specification.new do |spec|
  spec.name          = "can_haz_evatr"
  spec.version       = CanHazEvatr::VERSION
  spec.authors       = ["Lars Brillert"]
  spec.email         = ["lars@hackersthinkers.com"]

  spec.summary       = %q{Validate your vat ids against the eVATr service}
  spec.description   = %q{Because its a law, you have to valdate VAT ids before you invoice your customers. Using the eVATr webservice helps you do this}
  spec.homepage      = "https://github.com/hackersthinkers/can_haz_evatr"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/hackersthinkers/can_haz_evatr"
    spec.metadata["changelog_uri"] = "https://github.com/hackersthinkers/can_haz_evatr/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "activemodel", "> 5"
  spec.add_dependency "activesupport", "> 5"
  spec.add_dependency "faraday", ">= 1.0"
  spec.add_dependency "ostruct"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
