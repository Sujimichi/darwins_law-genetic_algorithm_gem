require "darwins_law/version"
require "darwins_law/genetic_algorithm"

module DarwinsLaw
  class GA < GeneticAlgorithm
  end
end

class TestThing < GeneticAlgorithm
  include PopulationSorter
end

class GA < GeneticAlgorithm
end
