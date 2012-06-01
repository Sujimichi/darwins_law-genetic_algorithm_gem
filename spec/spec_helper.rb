require 'rubygems'
require 'bundler/setup'

require './lib/darwins_law.rb' 

RSpec.configure do |config|
  # some (optional) config here
end

def assert_basic_evolution ga = @ga
  ga.population.flatten.max.should <= 1
  ga.evolve(100)
  ga.population.flatten.max.should >= 1 
  ga.population.flatten.max.should < 2
  ga.evolve(500)
  ga.population.flatten.max.should >= 2 
  ga.population.flatten.max.should < 4
  ga.evolve(800)
  ga.population.flatten.max.should >= 4 

end

