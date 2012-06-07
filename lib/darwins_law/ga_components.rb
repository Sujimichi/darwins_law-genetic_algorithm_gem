module FitnessCaching
  attr_accessor :cache, :cache_fitness

  def config
    defaults = {:cache_fitness => true}
    conf = super
    @config = defaults.merge(conf)
  end

  def fitness_of genome
    @cache_fitness = true unless defined? @cache_fitness
    #@cache = {} unless @cache_fitness 
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


  def config
    defaults = {:show_breeding_event => true}
    conf = super
    conf = defaults.merge(conf)
    if conf[:show_breeding_event].to_s.include?("every")
      conf[:interval_for][:breeding_event] = conf[:show_breeding_event].to_s.sub("every_","").to_i 
    elsif conf[:show_breeding_event].eql?(:with_best)
      conf[:interval_for][:breeding_event] = :with_best
    else
      conf[:interval_for][:breeding_event] = 1
    end
    @config = conf
  end

  def single_generation
    @mut_count = 0
    super
    show_breeding_event if should_show?(:breeding_event)
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



end

module ConvergenceMonitor
  attr_accessor :convergence

  def config
    defaults = {}
    conf = super
    conf[:interval_for][:record_convergence] = 1
    conf[:interval_for][:current_convergence] = 1
    @config = conf
  end
  

  def single_generation
    @convergence ||= []
    super
    @convergence << [@current_generation, current_convergence] if should_do?(:record_convergence)
    show_current_convergence(:as_percent_bar) if should_show?(:current_convergence)
  end

  def current_convergence
    n = @population.group_by{|genome| genome}.sort_by{|i| i.last.size}.last.last.size.to_f
    s = @population.size.to_f
    i = (n/s)
  end


  def show_current_convergence as = :as_percent
    case as
    when :as_percent
      puts "Population is #{current_convergence*100}% converged"
    when :as_percent_bar
      gen = @current_generation
      c = current_convergence
      s = Array.new([0,(6 - gen.to_s.length)].max){" "}.join
      t = 50 #total size
      m = (c * t).round #maker size
      g = (t - m) #size of whitespace (gap)
      
      puts "#{s}#{gen} |#{Array.new(m){'='}.join}#{Array.new(g){' '}.join}|#{(c*100).round(2)}%"

    when :as_plot


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
