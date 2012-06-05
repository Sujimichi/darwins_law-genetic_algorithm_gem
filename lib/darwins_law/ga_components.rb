module FitnessCaching
  attr_accessor :cache, :cache_fitness

  def fitness_of genome
    @cache_fitness = true unless defined? @cache_fitness
    return super unless @cache_fitness  #return fitness as norm if caching is off   
    update_cache_for(genome, super) unless cache[genome] #update cache if value not present. call fitness_of in superclass to get fitness evaluated
    @cache[genome] #return cached value
  end  

  def update_cache_for genome, fitness
    @cache[genome] = fitness
  end

  def cache
    @cache = {} unless defined? @cache
    @cache
  end

end

module EventOutput
  attr_accessor :phenotype_for

  CurBestStr = "*"
  NewBestStr = "**"

  def single_generation
    @mut_count = 0
    super
    show_breeding_event if @verbose && should_show?(:breeding_event)
  end

  def mutate gene
    @mut_count ||= 0; @mut_count += 1 #increase the mutation count.  should be reset for each generation.
    super
  end

  def update_cache_for genome, fitness
    super
    @phenotype_for = {} unless defined? @phenotype_for
    @phenotype_for[genome] = @fitness_data[:phenotype] unless @fitness_data[:phenotype].nil? || @fitness_data[:phenotype].empty?
  end

  def show_breeding_event
    max_p = @breeding_pair.map{|p| p.join.size }.max
    max_p = 32 if max_p > 32
    g1, g2 = @breeding_pair.map{|p| (max_p >= 32) ? digest(p.join) : [p, Array.new(max_p - p.join.size){' '}].join }
    f1, f2 = @breeding_pair.map{|p| @cache[p] } if @cache
    offspring  = (@offspring.join.size >= 32 ) ? digest(@offspring.join) : @offspring.join
    new_fit = @cache[@offspring] if @cache 
    mutant = (@mut_count && @mut_count.eql?(0)) ? Array.new(8){'-'}.join : "Mutant(#{@mut_count})"
    @phenotype_for = {} unless defined? @phenotype_for


    m = []
    m << "#{@phenotype_for[@breeding_pair[0]]}" if @phenotype_for[@breeding_pair[0]]
    m << "#{g1}--\\#{genome_comment(@breeding_pair[0],f1)}"
    m << "#{Array.new(max_p){' '}.join}   }>-#{mutant}-#{offspring}#{genome_comment(@offspring,new_fit)}"
    m << "#{g2}--/#{genome_comment(@breeding_pair[1],f2)}"
    m << "#{@phenotype_for[@breeding_pair[1]]}" if @phenotype_for[@breeding_pair[1]]
    m << "\n\n"
    
    puts m
  end


  def genome_comment genome, fitness
    s = ""
    s << "#{fitness.round(2)}" if fitness
    s << "#{CurBestStr}" if genome == @best[:genome]
    s = " <= #{s}" unless s.empty?
    s
  end  

  def digest genome
    d = Digest::MD5.new
    d << genome
    d.hexdigest
  end  

  #called in GeneticAlgorithm::Base if it is initialized with the :show_breeding_event arg
  def set_interval args
    if args[:show_breeding_event].eql?(true) || args[:show_breeding_event].eql?(:each_time)
      @interval_for[:breeding_event] = 1 
    elsif args[:show_breeding_event].to_s.include?("every")  
      @interval_for[:breeding_event] = args[:show_breeding_event].to_s.sub("every_","").to_i 
    elsif args[:show_breeding_event].eql?(:with_best)
      @interval_for[:breeding_event] = :with_best
    else
      @interval_for[:breeding_event] = nil
    end
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
