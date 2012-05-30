
module PopulationTools
  require 'digest'
  
  def ordered_population
    population.sort_by{|member| fitness(member)}.reverse
  end

  def best
    ordered_population.first
  end

  def digest genome
    d = Digest::MD5.new
    d << genome
    d.hexdigest
  end

end


module MatingRituals

  def microbial_recombination
    #Select two members at random and sort by fitness, select.last => fitter
    select = (0..@popsize-1).sort_by{rand}[0,2].sort_by {|ind| fitness_of(@population[ind]) }
    pair = [@population[select.first], @population[select.last]]
    #Replace % of weaker member's genes with fitter member's with a posibility of mutation.
    @population[select.first] = pair[0].zip(pair[1]).collect { |genes| pos_mutate( genes[ (rand<@cross_over_rate ? 1 : 0) ] )  }   
    show_breeding_event pair.last, pair.first, @population[select.first] if @verbose && @verbose[:breeding_details]
  end

end

class GeneticAlgorithm
  include MatingRituals
  include PopulationTools

  attr_accessor :population, :popsize, :gene_length, :generations, :mutation_rate, :mutation_function, :cross_over_rate, :fitness_function, :cache, :verbose
  
  def initialize args = {}
    @generations = args[:generations] || 1000         #Number of cycles to perform
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

    @current_generation = 0
    #@verbose = {:status => 100, :breeding_details => true}
    @verbose = {:status => 500, :breeding_details => true} if args[:verbose]

  end

  def evolve n_generations = @generations
    n_generations.times do |i|
      @current_generation += 1
      show_current_status if @verbose && @verbose[:status] && ((i+1)/@verbose[:status] == (i+1)/@verbose[:status].to_f)
      microbial_recombination
    end
  end

  def show_current_status
    #known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scores: #{@cache.values.max.round(2)}"
  end

  def show_breeding_event m1, m2, offspring    
    new_fit = @cache[offspring].round(2) if @cache[offspring]

    m = []
    #m << "#{@current_generation}"
    m << "#{@pheno_cache[m1]}" if @pheno_cache[m1]
    m << "#{digest m1.join}--\\ <-#{@cache[m1].round(2)}"
    m << "#{Array.new(32){' '}.join}   }>-----#{digest offspring.join}  "
    m.last << "<--#{new_fit}" if new_fit    
    m << "#{digest m2.join}--/ <-#{@cache[m2].round(2)}"
    m << "#{@pheno_cache[m2]}" if @pheno_cache[m2]
    m << "\n\n\n"

    puts m

  end
  def pos_mutate gene
    return gene if rand >= @mutation_rate/@gene_length #convert to per gene based muation rate
    @mutation_function.call(gene)
  end

  def fitness_of genome
    pheno_expresion = ""
    unless @cache_fitness  #return fitness as norm if caching is off   
      fitness = @fitness_function.call(genome, @current_generation, pheno_expresion)
    else
      @cache[genome] = @fitness_function.call(genome, @current_generation, pheno_expresion) unless @cache[genome] #update cache if value not present
      @pheno_cache[genome] = pheno_expresion unless @pheno_cache[genome]
      fitness = @cache[genome] #return cached value
      pheno_expresion = @pheno_cache[genome]
    end
    fitness
  end
end

# ga = GeneticAlgorithm.new(:generations => 4000, :mutation_function => :binary, :fitness_function => Proc.new{|g,gen,p| p << g.join; g.inject{|i,j| i+j} })
#    
# })
