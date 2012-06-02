module FitnessCaching
  attr_accessor :cache, :cache_fitness

  def fitness_of genome
    @cache_fitness = true unless defined? @cache_fitness
    return super unless @cache_fitness  #return fitness as norm if caching is off   
    unless cache[genome] #update cache if value not present
      cache[genome] = super #call fitness_of in superclass to get fitness evaluated
      #@pheno_cache[genome] = @info[:pheno_type] if @info && @info[:pheno_type]
    end
    @cache[genome] #return cached value
  end  

  def cache
    @cache = {} unless defined? @cache
    @cache
  end

end


module Reporter

  def single_generation
    super
    show_breeding_event(beeding_pair, offspring) if @verbose && self.respond_to?(:show_breeding_event) && @verbose[:breeding_details]
  end
  
  def show_current_status
    #known_fitness_of_pop = @population.map{|g| [g, @cache[g]]}.select{|n| !n.last.nil?}.group_by{|n| n.last}.sort_by{|n| n.first}.reverse
    puts "Generation: #{@current_generation}#{Array.new(8 - @current_generation.to_s.size){' '}.join} | Current Best scored: #{@best[:fitness].round(2)}"
  end

  def genome_comment genome, fitness
    "#{'*' if fitness == @best[:fitness]}#{@current_is_new_best ? 'Best so far' : ''} "
  end

  def digest genome
    d = Digest::MD5.new
    d << genome
    d.hexdigest
  end  



  def show_breeding_event mates, offspring    
    m1,m2 = mates
    new_fit = @cache[offspring].round(2) if @cache[offspring]

    m = []
    m << "#{@current_generation}"
  
    mutant = @mut_count.eql?(0) ? Array.new(8){'-'}.join : "Mutant(#{@mut_count})"

    m << "#{@pheno_cache[m1]}" if @pheno_cache[m1]
    m << "#{digest m1.join}--\\ <= #{@cache[m1].round(2)} #{genome_comment(m1,@cache[m1])}"   
    m << "#{Array.new(32){' '}.join}   }>-#{mutant}-#{digest offspring.join}  "  
    m.last << "<= #{new_fit}" if new_fit    
    m << "#{digest m2.join}--/ <= #{@cache[m2].round(2)}"
    m << "#{@pheno_cache[m2]}" if @pheno_cache[m2]
    m << "\n\n"

    puts m
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
