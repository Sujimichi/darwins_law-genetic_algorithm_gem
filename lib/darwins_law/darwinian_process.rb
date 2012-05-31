class DarwinianProcess

  attr_accessor :cross_over_rate, :mutation_rate, :mutation_function, :gene_length

  def initialize
    @cross_over_rate = 0.5
    @mutation_rate = 0.1
    @mutation_function = Proc.new{|gene| gene + (rand - 0.5) }
    @fitness_function  = Proc.new{|genome| genome.inject{|i,j| i + j }}
  end

  def evolve n_generations = @generations
    n_generations.times do |i|   
      breeding_pair = from_population( select_random(2) )#pick two members at random from population 
      offspring = recombine *breeding_pair #and produce an offspring by combining thier dna (and maybe a little mutation)      
      contestant_index = select_random(1)         #select random member (as contestant) and keep track of index
      contestant = @population[contestant_index]  #select the contestant from pop
      winner = [contestant, offspring].sort_by{|genome| fitness_of(genome)}.last #sort contestant and offspring by fitness and select winner
      @population[contestant_index] = winner #put the winner in the contestants place in the population
      @current_generation += 1
      #show_current_status if @verbose && @verbose[:status] && ((i+1)/@verbose[:status] == (i+1)/@verbose[:status].to_f)     
    end
  end

  
  ####
  ##Selection
  #
  
  #return random indexes to members in population
  def select_random n = 2
    select = (0..@population.size-1).sort_by{rand}[0,n] #create array 0 to popsize, sort by rand and take n.  ensures diff rand ints within pop
  end

  #return indexed members from the population
  def select_from_population sel_index = select_random
    sel_index.map{|index| @population[index]}  #select members from pop by randomly generated index
  end
  alias from_population select_from_population
  alias select_pair select_from_population

  ##Select and Compete
  #return random indexes to members in population, sorted with the fittest member first
  def sorted_random_members n = 2
    select_random(n).sort_by{|index| fitness_of(@population[index]) }.reverse
  end

  ##Select and Compete
  #return a random pair from the population, ordered fittest first
  def select_sorted_pair sel_index = select_random
    select_from_population(sel_index).sort_by {|genome| fitness_of(genome) }.reverse
  end

  
  ####
  ##Recombination
  #
  
  #takes two genomes (as array or separatly) and forms new genome by recombination
  #order if genomes is important when not using a 0.5 cross_over_rate.  genomes should be fittest first.
  def recombine *genomes
    fitter, weaker = genomes
    weaker.zip(fitter).map{ |genes| 
      apply_possible_muation{
        genes[ (random<@cross_over_rate ? 1 : 0) ] 
      }
    }
  end



  ####
  ##Mutation
  #
  
  #adjust the value of a given gene according to the Proc in @mutation_function
  def mutate gene
    @mut_count ||= 0; @mut_count += 1 #increase the mutation count.  should be reset in the breeding process.
    @mutation_function.call(gene)
  end

  #possibly applies a mutation to the given gene based on @mutation_rate
  #gene can be given as an arg, or returned by the given block.
  def apply_possible_muation gene=nil, &blk
    gene = yield if blk #get gene as result of block
    return gene if random >= @mutation_rate/@gene_length.to_f #convert to per gene based muation rate
    mutate(gene)  
  end
  alias pos_mutate apply_possible_muation 



  ####
  ##Competition
  #

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

  def random
    Kernel.rand
  end
end
