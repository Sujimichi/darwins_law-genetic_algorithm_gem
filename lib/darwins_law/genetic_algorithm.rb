class GeneticAlgorithm
   def initialize args = {}
     self::Microbial.new(args)
   end
end

class GeneticAlgorithm::Base < DarwinianProcess 
  attr_accessor :verbose, :best
    
  def initialize args = {}

    self.extend(FitnessCaching) if args[:cache_fitness]

    @popsize            = args[:popsize]            || 30       #Number of members (genomes) in the population
    @gene_length        = args[:gene_length]        || 10       #Number of bit (genes) in a genome
    @generations        = args[:generations]        || 500      #Number of cycles to perform

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
    @current_generation = 0

    @verbose = args[:verbose] || false
    @interval_for = {:status => 100}
  end

  def evolve n_generations = @generations
    n_generations.times do |i| 
      single_generation
      show_current_status if @verbose && ((i+1)/@interval_for[:status] == (i+1)/@interval_for[:status].to_f)
      @current_generation += 1
    end
  end

  def fitness_of genome
    fitness = super genome #lol
    @best = {:genome => genome, :fitness => fitness} if @best && (@best[:fitness].nil? || fitness > @best[:fitness]  )
    fitness
  end

  def show_current_status
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

end


class GeneticAlgorithm::Base

  def single_generation
    @breeding_pair = from_population( select_random(2) )#pick two members at random from population 
    @offspring = recombine *@breeding_pair #and produce an offspring by combining thier dna (and maybe a little mutation)      
    contestant = from_population(contestant_index = select_random(1)) #select another random member (as contestant) and keep track of index
    winner = [*contestant, @offspring].sort_by{|genome| fitness_of(genome)}.last #sort contestant and offspring by fitness and select winner
    @population[*contestant_index] = winner #put the winner in the contestants place in the population    
  end  

end

class GeneticAlgorithm::Standard < GeneticAlgorithm::Base 
  
end


class GeneticAlgorithm::Microbial < GeneticAlgorithm::Base 
  #include Reporter

  def initialize args = {}
    super
    @breeding_type = :microbial
    @cross_over_rate = args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination
  end

  def single_generation
    @mut_count = 0
    #Select two members at random and sort by fitness, select.first => fitter
    @beeding_pair = from_population( index = select_sorted_random_members(2) )
    @offspring = recombine *@beeding_pair #Replace % of weaker member's genes with fitter member's with a posibility of mutation.
    @population[index.last] = @offspring
  end  
end

##Temp stuff
#
##known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse

