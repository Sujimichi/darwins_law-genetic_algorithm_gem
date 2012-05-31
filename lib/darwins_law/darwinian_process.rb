class DarwinianProcess
  include MatingRituals
  attr_accessor :cross_over_rate, :mutation_rate, :mutation_function, :gene_length, :population

  def initialize args = {}
    @breeding_type = :standard
    @cross_over_rate = args[:cross_over_rate] || 0.5  #prob. of selecting gene from fitter member during recombination

    @current_generation = 0
    @generations = args[:generations] || 500          #Number of cycles to perform
    @gene_length = args[:gene_length] || 10           #Number of bit (genes) in a genome
    


    #define mutation rate and function
    @mutation_rate = args[:mutation_rate] || 0.1      #Per genome prob. of mutation (see readme)   
    @mutation_function = args[:mutation_function] || :decimal
    @mutation_function = Proc.new{|gene| gene + (rand - 0.5) } if @mutation_function.eql?(:decimal)
    @mutation_function = Proc.new{|gene| (gene-1).abs } if @mutation_function.eql?(:binary)    
        
    #define fitness function
    @fitness_function = args[:fitness_function] || args[:fitness] || Proc.new{|genome| genome.inject{|i,j| i+j} }

    @population = Array.new(2){Array.new(10){rand.round}}
    @best = {:genome => [], :fitness => nil}
    @verbose = false
  end

  def evolve n_generations = @generations
    n_generations.times do |i|
      self.send("#{@breeding_type}_breeding")
      @current_generation += 1
      show_current_status if @verbose && @verbose[:status] && ((i+1)/@verbose[:status] == (i+1)/@verbose[:status].to_f)     
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

   
  ####
  ##Competition
  #

  def fitness_of genome      
    fitness = @fitness_function.call(genome)
    @best = {:genome => genome, :fitness => fitness} if @best && (@best[:fitness].nil? || fitness > @best[:fitness]  )
    fitness
  end
  
  ##Select and Compete
  #return random indexes to members in population, sorted with the fittest member first
  def select_sorted_random_members n = 2
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
    fitter.zip(weaker).map{ |genes| with_possible_muation{ genes[ (random<@cross_over_rate ? 0 : 1) ] } }
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
  def with_possible_muation gene=nil, &blk
    gene = yield if blk #get gene as result of block
    return gene if random >= @mutation_rate/@gene_length.to_f #convert to per gene based muation rate
    mutate(gene)  
  end
  alias apply_possible_muation with_possible_muation 



  def show_current_status
    #known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

  def random
    Kernel.rand
  end
end
