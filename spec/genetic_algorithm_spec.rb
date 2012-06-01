require 'spec_helper'
require 'fileutils'


describe GeneticAlgorithm::Base do

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
 
  describe "tracking best so far" do 
    it 'should evolve a population' do 
      @ga = GeneticAlgorithm::Base.new(:mutation_rate => 0.1, :mutation_function => :binary)
      @ga.population = Array.new(20){Array.new(5){rand.round}}
      @ga.best.should be_a(Hash)
      @ga.best[:fitness].should be_nil
      @ga.best[:genome].should be_empty

      @ga.evolve(5)
      @ga.best[:fitness].should_not be_nil
      @ga.best[:genome].should_not be_empty
      best1 = @ga.best

      @ga.evolve
      @ga.best[:fitness].should == 5
      @ga.best[:genome].should == [1,1,1,1,1]
    end
  end

end




describe GeneticAlgorithm::Caching do 
 
  describe "evolving a population" do 
  
    it 'should evolve a population' do 
      @ga = GeneticAlgorithm::Caching.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
      assert_basic_evolution
    end
 
  end
  
  
  describe "caching geneme fitness" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Caching.new
    end

    it 'should cache a genomes fitness against a record of that genome' do
      @ga.cache.should be_empty
      fitness = @ga.fitness_of([1,1,1,1])
      @ga.cache[[1,1,1,1]].should == fitness
    end

    it 'should not cache if @cache_fitness is false' do
      @ga.cache.should be_empty
      @ga.cache_fitness = false
      fitness = @ga.fitness_of([1,1,1,1])
      @ga.cache.should be_empty
    end

    it 'should return different values for different genomes' do 
      g1 = Array.new(150){rand}
      g2 = Array.new(150){rand}
      f1 = @ga.fitness_of g1
      f2 = @ga.fitness_of g2
      
      @ga.cache.keys.size.should == 2
      @ga.cache[g1].should == f1
    end

    it 'should return nil when a tiny change has been made to the genome' do 
      g1 = Array.new(150){rand}
      f1 = @ga.fitness_of g1
      g1[(rand*149).round] += 0.000000000001
      @ga.cache[g1].should be_nil
    end

    it 'should continue to track best' do 
      @ga.best[:genome].should be_empty
      @ga.fitness_of([1,0,0,0])
      @ga.best[:genome].should == [1,0,0,0]
      @ga.best[:fitness].should == 1
      @ga.fitness_of([1,0,1,1])
      @ga.best[:fitness].should == 3

    end

    describe "extending existing GA with Caching" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new
        @ga.extend FitnessCaching
      end

      it 'should cache a genomes fitness against a record of that genome' do
        @ga.cache.should be_empty
        fitness = @ga.fitness_of([1,1,1,1])
        @ga.cache[[1,1,1,1]].should == fitness
      end


    end

  end

end

describe GeneticAlgorithm::Microbial do 
 
  describe "evolving a population" do 
  
    it 'should evolve a population' do 
      @ga = GeneticAlgorithm::Microbial.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3)
      assert_basic_evolution
    end
 
  end
  
end
