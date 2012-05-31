
class GeneticAlgorithm < DarwinianProcess
  include Reporter
  include PopulationTools

  attr_accessor :population, :popsize, :gene_length, :generations, :mutation_rate, :mutation_function, :cross_over_rate, :fitness_function, :cache, :verbose, :best
  

  def initialize args = {}
    super
    @breeding_type = :microbial
    @cross_over_rate = args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination

    #Initialize population    
    if args[:population]
      @population = args[:population]
      @popsize = @population.size
      raise "genomes must be same size" unless @population.map{|g| g.size}.uniq.size.eql?(1)
      @gene_length = @population.first.size
    else
      @popsize = args[:popsize] || 30                   #Number of members (genomes) in the population
      args[:init_pop_with] ||= 0
      args[:init_pop_with] = Proc.new{ (rand).round(2) } if args[:init_pop_with].eql?(:rand)
      pop_init_func = args[:init_pop_with].is_a?(Proc) ? args[:init_pop_with] : Proc.new{ args[:init_pop_with] }
      @population = Array.new(@popsize){ Array.new(@gene_length){ pop_init_func.call }}   
    end

    @cache = {}
    @cache_fitness = args[:cache_fitness] || true
    @pheno_cache = {}


    @verbose = {:status => 500, :breeding_details => true} if args[:verbose]

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


