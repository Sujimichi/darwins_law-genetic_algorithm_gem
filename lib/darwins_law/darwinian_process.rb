#DarwinianProcess defines the core mecahisums of evolution, selection, competition, recombination and mutation minus the actual evolutionary loop.
#This class does not actually function as a genetic algorithm, just defines the common logic.
#GeneticAlgorithm classes will inherit this and will then add extra functionality and provide different 'recipies' for performing evolution.
class DarwinianProcess
  attr_accessor :cross_over_rate, :mutation_rate, :fitness_function, :mutation_function
  attr_accessor :generations, :gene_length, :population, :popsize
 
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

  #return the fitness of a genome based on the @fitness_function.
  def fitness_of genome 
    @fitness_evaluation_data ||= {}
    @fitness_function.call(genome, @fitness_evaluation_data)
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


  #This random is used in place of rand in some places simply for the easy of testing, the effect is the same.
  #rand on its own can't easily be stubbed, but Kernel.stub!(:rand) works.  Testing recombination and mutation 
  #methods requires having control over rand.
  def random
    Kernel.rand
  end

end
