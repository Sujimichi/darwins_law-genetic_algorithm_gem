require 'spec_helper'


describe GeneticAlgorithm::Base do

  it 'should have set a number of instance variables' do 
    @ga = GeneticAlgorithm::Base.new
    vars = [:@popsize, :@gene_length, :@cross_over_rate, :@mutation_rate, :@generations, :@population, :@mutation_function, :@fitness_function]
    i_vars = @ga.instance_variables
    vars.map{|v| i_vars.should be_include(v)}      
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

    it 'should evolve a population' do 
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

end




describe GeneticAlgorithm::Standard do 

  it 'should include the fitness caching and reporter modules' #do 
    #GeneticAlgorithm::Standard.included_modules.should be_include FitnessCaching
    #GeneticAlgorithm::Standard.included_modules.should be_include Reporter
  #end
  
  it 'should have ancestors' do 
    [GeneticAlgorithm::Base, DarwinianProcess].each do |ancestor|
      GeneticAlgorithm::Standard.ancestors.should be_include ancestor
    end
  end

  it 'should evolve a population' do 
    @ga = GeneticAlgorithm::Standard.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
    assert_basic_evolution
  end

end



describe GeneticAlgorithm::Microbial do 
 
  it 'should include the fitness caching and reporter modules' #do 
    #GeneticAlgorithm::Standard.included_modules.should be_include FitnessCaching
    #GeneticAlgorithm::Standard.included_modules.should be_include Reporter
  #end
  
  it 'should evolve a population' do 
    @ga = GeneticAlgorithm::Microbial.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
    assert_basic_evolution
  end
  
end
