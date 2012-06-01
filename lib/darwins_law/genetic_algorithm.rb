class GeneticAlgorithm
end

class GeneticAlgorithm::Base < DarwinianProcess 
  include MatingRituals

  attr_accessor :verbose, :best
    
  def initialize args = {}

    @breeding_type      = args[:breeding_type]      || :standard #defines what type of evolution to perform; :standard or :microbial
    @generations        = args[:generations]        || 500       #Number of cycles to perform
    @gene_length        = args[:gene_length]        || 10        #Number of bit (genes) in a genome
    @popsize            = args[:popsize]            || 30        #Number of members (genomes) in the population

    @cross_over_rate    = args[:cross_over_rate]    || 0.5      #prob. of selecting gene from fitter member during recombination    
    @mutation_rate      = args[:mutation_rate]      || 0.1      #Per genome prob. of mutation (see readme)   
    @mutation_function  = args[:mutation_function]  || :decimal #type of mutation to apply to a gene. :decimal, :binary or Proc 
    @mutation_function  = Proc.new{|gene| gene + (rand - 0.5) } if @mutation_function.eql?(:decimal)  #binary mut; 0->1; 1->0
    @mutation_function  = Proc.new{|gene| (gene-1).abs }        if @mutation_function.eql?(:binary)   #decimal mut;

    @fitness_function   = args[:fitness_function] || args[:fitness] || Proc.new{|genome| genome.inject{|i,j| i+j} } #define fitness function
    args[:init_pop_with]||= 0
    args[:init_pop_with]= Proc.new{ (rand).round(2) } if args[:init_pop_with].eql?(:rand)

    
    #Initialize population    
    if args[:population]
      @population = args[:population]
      raise "genomes must be same size" unless @population.map{|g| g.size}.uniq.size.eql?(1)
      @popsize = @population.size
      @gene_length = @population.first.size
    else     
      pop_init_func = args[:init_pop_with].is_a?(Proc) ? args[:init_pop_with] : Proc.new{ args[:init_pop_with] }
      @population = Array.new(@popsize){ Array.new(@gene_length){ pop_init_func.call }}   
    end

    @best = {:genome => [], :fitness => nil}
    @verbose = {:status => 100} if args[:verbose]
    @current_generation = 0
  end

  def evolve n_generations = @generations
    n_generations.times do |i|
      self.send("#{@breeding_type}_breeding")
      if @verbose
        show_breeding_event(@beeding_pair, @offspring) if self.respond_to?(:show_breeding_event) && @verbose[:breeding_details]
        show_current_status if @verbose[:status] && ((i+1)/@verbose[:status] == (i+1)/@verbose[:status].to_f)          
      end
      @current_generation += 1
    end
  end

  def show_current_status
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

  def fitness_of genome
    fitness = super genome #lol
    @best = {:genome => genome, :fitness => fitness} if @best && (@best[:fitness].nil? || fitness > @best[:fitness]  )
    fitness
  end

end


class GeneticAlgorithm::Caching < GeneticAlgorithm::Base
  include FitnessCaching

  def initialize args = {}
    super
    @cache = {}
    @pheno_cache = {}  
    @cache_fitness = args[:cache_fitness] || true
  end
  
end

class GeneticAlgorithm::Standard < GeneticAlgorithm::Caching 
  include Reporter

  def initialize args = {}
    super
    @verbose = {:status => 100, :breeding_details => true} if args[:verbose]
  end
end


class GeneticAlgorithm::Microbial < GeneticAlgorithm::Caching 
  include Reporter

  def initialize args = {}
    super
    @breeding_type = :microbial
    @cross_over_rate = args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination
    @verbose = {:status => 100, :breeding_details => true} if args[:verbose]
  end
end

##Temp stuff
#
##known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse

