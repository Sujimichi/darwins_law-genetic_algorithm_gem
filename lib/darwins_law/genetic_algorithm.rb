class GeneticAlgorithm

  attr_accessor :population, :popsize, :gene_length, :generations, :mutation_rate, :mutation_function, :cross_over_rate, :fitness_function
  
  def initialize args = {}
    @generations = args[:generations] || 400          #Number of cycles to perform
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
  end

  def evolve
    @generations.times do |current_generation|
      #Select two members at random and sort by fitness, select.last => fitter
      select = (0..@popsize-1).sort_by{rand}[0,2].sort_by {|ind| fitness_of(@population[ind]) }      
      @population[select.first] = @population[select.first].zip(@population[select.last]).collect { |genes|
        pos_mutate( genes[ (rand<@cross_over_rate ? 1 : 0) ] ) #Replace % of weaker member's genes with fitter member's with a posibility of mutation.
      } 
    end
  end

  def pos_mutate gene
    return gene if rand >= @mutation_rate/@gene_length #convert to per gene based muation rate
    @mutation_function.call(gene)
  end

  def fitness_of genome
    @fitness_function.call(genome)
  end
end

module PopulationTools

  def ordered_population
    population.sort_by{|member| fitness(member)}.reverse
  end

  def best
    ordered_population.first
  end

end
