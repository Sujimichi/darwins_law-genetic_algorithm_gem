class Algorithms
end

class Algorithms::Base < DarwinianProcess
end

class CachingAlgorithm < DarwinianProcess
  include Reporter

  attr_accessor :cache
  

  def initialize args = {}
    super
    @cache = {}
    @cache_fitness = args[:cache_fitness] || true
    @pheno_cache = {}  
  end

  def fitness_of genome
    pheno_expresion = ""
    unless @cache_fitness  #return fitness as norm if caching is off   
      fitness = @fitness_function.call(genome, @current_generation, pheno_expresion)
    else
      @cache[genome] = @fitness_function.call(genome, @current_generation, pheno_expresion) unless @cache[genome] #update cache if value not present
      @pheno_cache[genome] = pheno_expresion unless @pheno_cache[genome] || pheno_expresion.empty?
      fitness = @cache[genome] #return cached value
    end

    @current_is_new_best = false
    if @best && (@best[:fitness].nil? || fitness > @best[:fitness]  )
      @current_is_new_best = true
      @best = {:genome => genome, :fitness => fitness}
    end
    fitness
  end  

end

class Algorithms:Standard < CachingAlgorithm
end


class Algorithms::Microbial < CachingAlgorithm
  def initialize args = {}
    super
    @breeding_type = :microbial
    @cross_over_rate = args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination
    @verbose = {:status => 100, :breeding_details => true} if args[:verbose]
  end
end
