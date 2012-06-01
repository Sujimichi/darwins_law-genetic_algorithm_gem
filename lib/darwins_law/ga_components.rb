
module MatingRituals

  def microbial_breeding
    @mut_count = 0
    #Select two members at random and sort by fitness, select.first => fitter
    beeding_pair = from_population( index = select_sorted_random_members(2) )
    @population[index.last] = recombine *beeding_pair #Replace % of weaker member's genes with fitter member's with a posibility of mutation.
    show_breeding_event beeding_pair, @population[index.last] if @verbose && @verbose[:breeding_details]
  end

  def standard_breeding
    breeding_pair = from_population( select_random(2) )#pick two members at random from population 
    offspring = recombine *breeding_pair #and produce an offspring by combining thier dna (and maybe a little mutation)      
    contestant_index = select_random(1).first   #select random member (as contestant) and keep track of index
    contestant = @population[contestant_index]  #select the contestant from pop
    winner = [contestant, offspring].sort_by{|genome| fitness_of(genome)}.last #sort contestant and offspring by fitness and select winner
    @population[contestant_index] = winner #put the winner in the contestants place in the population
  end

end


module Reporter
  require 'digest'
  
  def show_current_status
    #known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

  def genome_comment genome, fitness
    "#{'*' if fitness == @best[:fitness]}#{@current_is_new_best ? 'Best so far' : ''} "
  end
  

  def show_breeding_event mates, offspring    
    m1,m2 = mates
    new_fit = @cache[offspring].round(2) if @cache[offspring]

    m = []
    m << "#{@current_generation}"
    

    m << "#{@pheno_cache[m1]}" if @pheno_cache[m1]
    m << "#{digest m1.join}--\\ <= #{@cache[m1].round(2)} #{genome_comment(m1,@cache[m1])}"
    mutant = @mut_count.eql?(0) ? Array.new(8){'-'}.join : "Mutant(#{@mut_count})"
    m << "#{Array.new(32){' '}.join}   }>-#{mutant}-#{digest offspring.join}  "  
    m.last << "<= #{new_fit}" if new_fit    
    m << "#{digest m2.join}--/ <= #{@cache[m2].round(2)}"
    m << "#{@pheno_cache[m2]}" if @pheno_cache[m2]
    m << "\n\n"

    puts m

  end

  def digest genome
    d = Digest::MD5.new
    d << genome
    d.hexdigest
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
