
class GeneticAlgorithm < DarwinianProcess
  include Reporter
  include MatingRituals
  include PopulationTools

  attr_accessor :population, :popsize, :gene_length, :generations, :mutation_rate, :mutation_function, :cross_over_rate, :fitness_function, :cache, :verbose, :best
  
  def initialize args = {}
    @generations = args[:generations] || 500          #Number of cycles to perform
    @gene_length = args[:gene_length] || 10           #Number of bit (genes) in a genome
    @cross_over_rate = args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination
    
    #define mutation rate and function
    @mutation_rate = args[:mutation_rate] || 0.1      #Per genome prob. of mutation (see readme)   
    @mutation_function = args[:mutation_function] || :decimal
    @mutation_function = Proc.new{|n| (n + (rand - 0.5)) } if @mutation_function.eql?(:decimal)
    @mutation_function = Proc.new{|n| (n-1).abs } if @mutation_function.eql?(:binary)

    #define fitness function
    @fitness_function = args[:fitness_function] || args[:fitness] || Proc.new{|genome| genome.inject{|i,j| i+j} }

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

    @best = {:genome => [], :fitness => nil}

    @current_generation = 0
    #@verbose = {:status => 100, :breeding_details => true}
    @verbose = {:status => 500, :breeding_details => true} if args[:verbose]

  end


  def evolve n_generations = @generations
    n_generations.times do |i|
      microbial_recombination #only doing microbial atm.  will have options to select recom_method.
      @current_generation += 1
      show_current_status if @verbose && @verbose[:status] && ((i+1)/@verbose[:status] == (i+1)/@verbose[:status].to_f)     
    end
  end
  
end


