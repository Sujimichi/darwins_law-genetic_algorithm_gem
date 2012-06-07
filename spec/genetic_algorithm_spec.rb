require 'spec_helper'

def test_config conf, should_contain
  should_contain.each do |k,v|
    conf.should have_key(k)
    conf[k].should == v unless v.eql?("whatever")
  end
end

describe GeneticAlgorithm::Base do

  it 'should have set a number of instance variables' do 
    @ga = GeneticAlgorithm::Base.new
    vars = [:@popsize, :@gene_length, :@cross_over_rate, :@mutation_rate, :@generations, :@population, :@mutation_function, :@fitness_function]
    i_vars = @ga.instance_variables
    vars.map{|v| i_vars.should be_include(v)}      
  end


  describe "config" do 
    it 'should return the default config args when none are given in init' do 
      @ga = GeneticAlgorithm::Base.new
      @ga.config.should be_a Hash
      conf = @ga.config
      test_config conf, {:verbose => false, :interval_for => {:status => 100}}
    end

    it 'should return user settings when given and defaults for non specified' do 
      @ga = GeneticAlgorithm::Base.new(:verbose => true)
      conf = @ga.config
      test_config conf, {:verbose => true, :interval_for => {:status => 100}}
    end

    it 'should allow method access to config keys' do 
      @ga = GeneticAlgorithm::Base.new(:verbose => true)
      @ga.verbose.should == true
    end

    describe "being automatically extended by extending ::Base with certain modules" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new
      end
      describe "FitnessCaching module" do 

        it 'should extend the config with with defaults when none are present' do 
          @ga.config.should_not have_key :cache_fitness
          @ga.extend FitnessCaching
          @ga.config.should have_key :cache_fitness
          @ga.config[:cache_fitness].should be_true
        end

        it 'should extend the config but not replace present values with defaults' do         
          @ga = GeneticAlgorithm::Base.new(:cache_fitness => false)
          @ga.config.should have_key :cache_fitness
          @ga.config[:cache_fitness].should be_false
          @ga.extend FitnessCaching
          @ga.config[:cache_fitness].should be_false      
        end
      end

      describe "ConvergenceMonitor" do 

        it 'should extend the config with with defaults when none are present' do 
          @ga.config[:interval_for].should_not have_key :record_convergence
          @ga.config[:interval_for].should_not have_key :current_convergance
          @ga.extend ConvergenceMonitor
          @ga.config[:interval_for].should have_key :record_convergence
          @ga.config[:interval_for].should have_key :current_convergence
          #@ga.config[:current_convergance].should == :as_percent_bar
        end


      end

      describe "EventOutput module" do 

        it 'should extend the config with with defaults when none are present' do 
          @ga.config.should_not have_key :show_breeding_event
          @ga.extend EventOutput
          @ga.config.should have_key :show_breeding_event
          @ga.config[:show_breeding_event].should be_true
        end

        it 'should extend the config for interval_for with breeding_event' do 
          @ga.config[:interval_for].should_not have_key(:breeding_event)
          @ga.extend EventOutput
          @ga.config[:interval_for].should have_key(:breeding_event)
        end

        it 'should set breeding_event to 1 when show_breeding_event is true' do 
          @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true)
          @ga.config[:interval_for][:breeding_event].should == 1
        end

        it 'should set breeding_event to n when show_breeding_event is every_n' do
          @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :every_20)
          @ga.config[:interval_for][:breeding_event].should == 20
          @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :every_100)
          @ga.config[:interval_for][:breeding_event].should == 100          
        end

        it 'should set breeding_event to :with_best when show_breeding_event is with_best' do
          @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :with_best)
          @ga.config[:interval_for][:breeding_event].should == :with_best          
        end

        it 'should not overwrite custom seting for breeding_event' do 
          @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :every_20)
          @ga.config[:interval_for][:breeding_event].should == 20
          @ga.config[:show_breeding_event] = :every_42
          @ga.config[:interval_for][:breeding_event].should == 42
        end

      end

    end
  end

  describe "population initialization" do 

    it 'should initialize population with all 0s' do 
      @ga = GeneticAlgorithm::Base.new(:gene_length => 4, :popsize => 10, :init_pop_with => 0)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should initialize population with all 1s' do 
      @ga = GeneticAlgorithm::Base.new(:gene_length => 4, :popsize => 10, :init_pop_with => 1)
      @ga.population.should == Array.new(10){Array.new(4){1}}
      @ga.population.uniq.size.should == 1
    end
    it 'should initialize population with all rand ' do      
      @ga = GeneticAlgorithm::Base.new(:gene_length => 4, :popsize => 10, :init_pop_with => :rand)
      @ga.population.uniq.size.should == 10
    end
    it 'should initialize population with all 0 by default' do      
      @ga = GeneticAlgorithm::Base.new(:gene_length => 4, :popsize => 10)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should be initialized with custom population' do 
      @ga = GeneticAlgorithm::Base.new(:population => [[0,0,0], [0,0,0]])
      @ga.population.should == [[0,0,0], [0,0,0]]
      @ga.popsize.should == 2
      @ga.gene_length.should == 3
    end

    it 'should throw error if genomes are different size' do 
      t = false
      begin
      @ga = GeneticAlgorithm::Base.new(:population => [[0,0,0], [0,0,0,1]])
      rescue
        t = true
      end
      t.should be_true
    end

  end

  describe "different mutation functions" do 

    it 'should have a default :decimal mutation function ' do 
      @ga = GeneticAlgorithm::Base.new(:mutation_rate => 10, :gene_length => 10) #config for mutation of every gene
      @ga.with_possible_muation(4).should_not == 4
      (@ga.with_possible_muation(4) >= 3.5 && @ga.with_possible_muation(4) <= 4.5).should be_true
    end

    it 'should have option for :binary mutation function ' do 
      @ga = GeneticAlgorithm::Base.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => :binary) #config for mutation of every gene
      @ga.with_possible_muation(0).should == 1
      @ga.with_possible_muation(1).should == 0
    end

    it 'should have option for :binary mutation function ' do 
      @ga = GeneticAlgorithm::Base.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => Proc.new{|gene| gene+2}) #config for mutation of every gene
      @ga.with_possible_muation(3).should == 5
      @ga.with_possible_muation(1).should == 3
    end

  end

  describe "different fitness function" do 
    
    it 'should have a default max_ones fitness function' do 
      @ga = GeneticAlgorithm::Base.new
      @ga.fitness_of([1,1,1,1,1]).should == 5
      @ga.fitness_of([2,1,0,1,2]).should == 6
    end

    it 'should take a custom fitness function' do 
      @ga = GeneticAlgorithm::Base.new(:fitness => Proc.new{|genome| genome.inject{|i,j| i + j} })
      @ga.fitness_of([1,1,1,1,1]).should == 5
      @ga.fitness_of([1,-1,1,-1,1]).should == 1    
      @ga.fitness_of([1,2,3,4,5]).should == 15

      @ga = GeneticAlgorithm::Base.new(:fitness => Proc.new{|genome| genome.inject{|i,j| i - j} })
      @ga.fitness_of([1,1,1,1,1]).should == -3
      @ga.fitness_of([1,-1,1,-1,1]).should == 1    
      @ga.fitness_of([1,2,3,4,5]).should == -13

      @ga = GeneticAlgorithm::Base.new(:fitness => Proc.new{|genome| genome.inject{|i,j| i * j} })
      @ga.fitness_of([1,1,1,1,1]).should == 1
      @ga.fitness_of([1,-1,1,-1,1]).should == 1    
      @ga.fitness_of([1,2,3,4,5]).should == 120
    end
    
  end

  describe "evolving a population" do 

    it 'should change the population' do 
      @ga = GeneticAlgorithm::Base.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
      assert_basic_evolution
    end
  
    it 'should run evolution with custom functions' do 
      @ga = GeneticAlgorithm::Base.new(
        :generations => 1000, 
        :gene_length => 4, 
        :mutation_rate => 0.3,
        :init_pop_with    => Proc.new{ rand*10 },
        :fitness_function => Proc.new{|genome| 0 - (0 - genome.inject{|i,j| i + j}).abs },
        :mutation_function=> Proc.new{|gene| gene + rand.round }
      )
      @ga.population.flatten.max.should > 8
      @ga.evolve     
      @ga.population.flatten.max.round.should_not > 3
    end

  end



  describe "tracking best so far" do 
    it 'should evolve a population' do 
      @ga = GeneticAlgorithm::Base.new
      @ga.best.should be_a(Hash)
      @ga.best[:fitness].should be_nil
      @ga.best[:genome].should be_empty

      @ga.fitness_of [1,0,1,0,1]
      @ga.best[:fitness].should == 3
      @ga.best[:genome].should == [1,0,1,0,1] 

      @ga.fitness_of [1,0,0,0,1]
      @ga.best[:fitness].should == 3
      @ga.best[:genome].should == [1,0,1,0,1] 

      @ga.fitness_of [1,0,0,1,1]  #when equally good but different genome is found, im not quite sure what to do.  currently keeping current best.
      @ga.best[:fitness].should == 3
      @ga.best[:genome].should == [1,0,1,0,1] 

      @ga.fitness_of [1,0,1,1,1]
      @ga.best[:fitness].should == 4
      @ga.best[:genome].should == [1,0,1,1,1] 
      
    end
  end

  describe "output of current best every n generations" do 
    it 'should have some tests'
  end

  

end




describe GeneticAlgorithm::Standard do 

  it 'should have ancestors' do 
    [GeneticAlgorithm::Base, DarwinianProcess].each do |ancestor|
      GeneticAlgorithm::Standard.ancestors.should be_include ancestor
    end
  end

  it 'should change the population' do 
    @ga = GeneticAlgorithm::Standard.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
    assert_basic_evolution
  end

end



describe GeneticAlgorithm::Microbial do 
 
  it 'should have ancestors' do 
    [GeneticAlgorithm::Base, DarwinianProcess].each do |ancestor|
      GeneticAlgorithm::Standard.ancestors.should be_include ancestor
    end
  end

  it 'should change the population' do 
    @ga = GeneticAlgorithm::Microbial.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
    assert_basic_evolution
  end
  
end
