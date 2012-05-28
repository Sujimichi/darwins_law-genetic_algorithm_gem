# -*- encoding: utf-8 -*-
require File.expand_path('../lib/darwins_law/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["sujimichi"]
  gem.email         = ["sujimichi@googlemail.com"]
  gem.description   = %q{simple genitic algorithm tool set}
  gem.summary       = %q{simple genitic algorithm tool set}
  gem.homepage      = ""


  gem.add_development_dependency('rspec')
  gem.add_development_dependency('ZenTest')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "darwins_law"
  gem.require_paths = ["lib"]
  gem.version       = DarwinsLaw::VERSION
end
