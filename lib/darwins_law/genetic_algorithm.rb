class GeneticAlgorithm

end

class GeneticAlgorithm::Base < DarwinianProcess 
  attr_accessor :best, :current_generation

  def initialize args = {}
    defaults = {
      :verbose => false,
      :interval_for => {
        :status => 100
      },

      :popsize => 30,#Number of members (genomes) in the population
      :gene_length => 10,#Number of bit (genes) in a genome
      :generations => 500,#Number of cycles to perform
      :cross_over_rate => 0.5,#prob. of selecting gene from fitter member during recombination    
      :mutation_rate => 0.1,#Per genome prob. of mutation (see readme)   
      :mutation_function => :decimal,#type of mutation to apply to a gene. :decimal, :binary or Proc 
      :fitness_function => Proc.new{|genome| genome.inject{|i,j| i+j} }, #define fitness function
      :init_pop_with => 0
    }

    args[:fitness_function] ||= args[:fitness] if args[:fitness] #fitness func can be passed in as :fitness if :fitness_function is not also included
    args[:init_pop_with] = Proc.new{ (rand).round(2) } if args[:init_pop_with].eql?(:rand)

    @config = defaults.merge!(args)

    self.extend(FitnessCaching) if @config[:cache_fitness]   
    self.extend(EventOutput)    if @config[:show_breeding_event]

    [:popsize, :gene_length, :generations, :cross_over_rate, :mutation_rate, :mutation_function, :fitness_function].each{|var_name|
      instance_variable_set("@#{var_name}", @config[var_name])
    }
    @mutation_function  = Proc.new{|gene| gene + (rand - 0.5) } if @mutation_function.eql?(:decimal)  #binary mut; 0->1; 1->0
    @mutation_function  = Proc.new{|gene| (gene-1).abs }        if @mutation_function.eql?(:binary)   #decimal mut;

    #Initialize population    
    if args[:population]
      @population = args[:population]
      raise "genomes must be same size" unless @population.map{|g| g.size}.uniq.size.eql?(1)
      @popsize = @population.size
      @gene_length = @population.first.size
    else     
      pop_init_func = @config[:init_pop_with].is_a?(Proc) ? @config[:init_pop_with] : Proc.new{ @config[:init_pop_with] }
      @population = Array.new(@config[:popsize]){ Array.new(@config[:gene_length]){ pop_init_func.call }}   
    end

    @best = {:genome => [], :fitness => nil}
    @current_generation = 0
  end


  #Evolution Loop - The method single_generation defines the actions to be performed on each cycle.
  #Microbial and Standard provide different single_generation methods and extending with certain modules will modify single_generation.
  def evolve n_generations = @generations
    n_generations.times do |i| 
      single_generation   #classes inheriting ::Base should override 'single_generation' with different evolutionary actions.
      show_current_status if should_show?(:status)
      @current_generation += 1
    end
  end

  #adds tracking of best genome to original method from DarwinianProcess.
  def fitness_of genome
    fitness = super genome #lol
    update_best genome, fitness
    fitness
  end

  def show_current_status
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

  def update_best genome, fitness
    @best = {:genome => genome, :fitness => fitness} if @best && (@best[:fitness].nil? || fitness > @best[:fitness]  )
  end

  def should_show? output_type = :status, i = @current_generation
    return false unless config[:verbose]
    return false unless config[:interval_for] && config[:interval_for].has_key?(output_type)
    ((i+1)/config[:interval_for][output_type] == (i+1)/config[:interval_for][output_type].to_f)
  end
  alias should_do? should_show?

  def config
    @config ||= {}
  end

  def method_missing method, *args
    return config[method] if config.keys.include?(method)
    super method, *args
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

  def initialize args = {}
    args[:cross_over_rate] || 0.7  #Prob. of selecting gene from fitter member during recombination
    super
  end

  def single_generation
    @beeding_pair = from_population( index = select_sorted_random_members(2) ) #Select two members at random and sort by fitness, select.first => fitter
    @offspring = recombine *@beeding_pair #Replace % of weaker member's genes with fitter member's with a posibility of mutation.
    @population[index.last] = @offspring
  end  
end
