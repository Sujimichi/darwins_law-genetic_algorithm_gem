require 'spec_helper'
require 'fileutils'


describe DarwinianProcess do
  before(:each) do 
    @darwin = DarwinianProcess.new
    @darwin.gene_length = 10    
    @pop = Array.new(10){Array.new(10){rand.round} }
    @darwin.instance_variable_set("@population", @pop)
    #Kernel.stub!(:rand).and_return(*[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])    
  end


  describe "population initialization" do 

    it 'should initialize population with all 0s' do 
      @ga = DarwinianProcess.new(:gene_length => 4, :popsize => 10, :init_pop_with => 0)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should initialize population with all 1s' do 
      @ga = DarwinianProcess.new(:gene_length => 4, :popsize => 10, :init_pop_with => 1)
      @ga.population.should == Array.new(10){Array.new(4){1}}
      @ga.population.uniq.size.should == 1
    end
    it 'should initialize population with all rand ' do      
      @ga = DarwinianProcess.new(:gene_length => 4, :popsize => 10, :init_pop_with => :rand)
      @ga.population.uniq.size.should == 10
    end
    it 'should initialize population with all 0 by default' do      
      @ga = DarwinianProcess.new(:gene_length => 4, :popsize => 10)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should be initialized with custom population' do 
      @ga = DarwinianProcess.new(:population => [[0,0,0], [0,0,0]])
      @ga.population.should == [[0,0,0], [0,0,0]]
      @ga.popsize.should == 2
      @ga.gene_length.should == 3
    end

    it 'should throw error if genomes are different size' do 
      t = false
      begin
      @ga = DarwinianProcess.new(:population => [[0,0,0], [0,0,0,1]])
      rescue
        t = true
      end
      t.should be_true
    end

  end

  describe "selection" do 

    it 'should return an index to n random members in the population' do 
      @darwin.select_random(2).size.should == 2
      @darwin.select_random(3).size.should == 3
      500.times do 
        index = @darwin.select_random(2)
        index.min.should >= 0
        index.max.should <= 29
      end   
    end

    it 'should not return the same two members' do 
      200.times{
        index = @darwin.select_random(2)
        index.first.should_not == index.last
      }
    end


    it 'should return two members from the population by given index' do 
      selected = @darwin.select_from_population([4,8])
      selected.map{|sel| @pop.index(sel)}.should == [4,8]
    end

    



  end

  describe "competition" do 
    it 'should return an index to n random members with the index sorted by fitness of member first' do
      20.times do 
        index = @darwin.select_sorted_random_members(2)
        @pop[index.first].inject{|i,j| i+j}.should >= @pop[index.last].inject{|i,j| i+j}
      end
    end

    it 'should return a sorted pair (fittest first)' do 
      @darwin.stub!(:fitness_of).and_return(*[4,5])
      @darwin.stub!(:select_from_population => [[1,1,1,1,0],[1,1,1,1,1]])
      pair = @darwin.select_sorted_pair
      pair.should == [[1,1,1,1,1],[1,1,1,1,0]]
    end 
  end
  
  describe "recombination" do 
    before(:each) do
      @parent1 = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      @parent2 = [-1,-2,-3,-4,-5,-6,-7,-8,-9,-10]
      Kernel.stub!(:rand).and_return(*[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])

      @darwin.should_receive(:with_possible_muation).and_yield().any_number_of_times
    end

    it 'should take two genomes and return a new genome' do 
      new_genome = @darwin.recombine @parent1, @parent2
      new_genome.size.should == 10
    end
    it 'should take two genomes as array of genomes and return new genome' do 
      new_genome = @darwin.recombine *[@parent1, @parent2]
      new_genome.size.should == 10
    end

    it 'should return a genome with elements from each parent' do
      new_genome = @darwin.recombine @parent1, @parent2
      @parent1.select{|i| new_genome.include?(i)}.size.should >= 1
      @parent2.select{|i| new_genome.include?(i)}.size.should >= 1     
    end

    it 'should make a new genome from half of either parent with 0.5 cross_over' do 
      new_genome = @darwin.recombine @parent1, @parent2
      new_genome.should == [ 1, 2, 3, 4, 5,-6,-7,-8,-9,-10]
      Kernel.stub!(:rand).and_return(*Array.new(5){[0,1]}.flatten)
      new_genome = @darwin.recombine @parent1, @parent2
      new_genome.should == [ 1, -2, 3, -4, 5, -6, 7, -8, 9, -10]
    end

    it 'should make a new genome with 70% from the first(fitter) parent' do 
      @darwin.cross_over_rate = 0.7
      new_genome = @darwin.recombine @parent1, @parent2
      new_genome.should == [ 1, 2, 3, 4, 5, 6, 7, -8, -9, -10]
    end
    it 'should make a new genome with 30% from the first(fitter) parent' do 
      @darwin.cross_over_rate = 0.3
      new_genome = @darwin.recombine @parent1, @parent2
      new_genome.should == [ 1, 2, 3, -4, -5, -6, -7, -8, -9, -10]
    end
    
  end

  describe "mutation" do 
    before(:each) do 
    end

    it 'should muatate a gene according to the muation_function' do 
      @darwin.mutation_function = Proc.new{|gene| gene+4}
      @darwin.mutate(5).should == 9
      @darwin.mutation_function = Proc.new{|gene| gene*2}
      @darwin.mutate(5).should == 10
    end

    it 'should apply mutation to a gene based on muation_rate' do 
      Kernel.stub!(:rand).and_return(*[0.5, 0.001])      
      @darwin.mutation_rate = 0.2
      @darwin.mutation_function = Proc.new{|gene| gene*2}
      @darwin.apply_possible_muation(3).should == 3
      @darwin.apply_possible_muation(3).should == 6
    end

    it 'should apply mutation to a gene based on muation_rate when gene is returned from a block' do 
      Kernel.stub!(:rand).and_return(*[0.5, 0.001])      
      @darwin.mutation_rate = 0.2
      @darwin.mutation_function = Proc.new{|gene| gene*2}
      @darwin.with_possible_muation{
        2+1
      }.should == 3
      @darwin.with_possible_muation{
        3+1
      }.should == 8
    end

    it 'should mutate with a high mutation rate' do 
      @darwin.mutation_function = Proc.new{|gene| gene*2}
      @darwin.gene_length = 10
      @darwin.mutation_rate = 10
      @darwin.apply_possible_muation{3+1}.should == 8
    end
  

    it 'should have a default :decimal mutation function ' do 
      @ga = DarwinianProcess.new(:mutation_rate => 10, :gene_length => 10) #config for mutation of every gene
      @ga.with_possible_muation(4).should_not == 4
      (@ga.with_possible_muation(4) >= 3.5 && @ga.with_possible_muation(4) <= 4.5).should be_true
    end

    it 'should have option for :binary mutation function ' do 
      @ga = DarwinianProcess.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => :binary) #config for mutation of every gene
      @ga.with_possible_muation(0).should == 1
      @ga.with_possible_muation(1).should == 0
    end

    it 'should have option for :binary mutation function ' do 
      @ga = DarwinianProcess.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => Proc.new{|gene| gene+2}) #config for mutation of every gene
      @ga.with_possible_muation(3).should == 5
      @ga.with_possible_muation(1).should == 3
    end

  end
  describe "fitness evaluation" do 
    it 'should have a default max_ones fitness function' do 
      @ga = DarwinianProcess.new
      @ga.fitness_of([1,1,1,1,1]).should == 5
      @ga.fitness_of([2,1,0,1,2]).should == 6
    end
    it 'should take a custom fitness function' do 
      @ga = DarwinianProcess.new(:fitness => Proc.new{|genome| genome.inject{|i,j| i-j} })
      @ga.fitness_of([1,1,1,1,1]).should == -3
      @ga.fitness_of([1,-1,1,-1,1]).should == 1    
    end
    
  end
  
  describe "evolve" do 
    it 'should evolve a population' do 
      @ga = DarwinianProcess.new(:popsize => 20, :gene_length => 5, :mutation_rate => 0.3, :mutation_function => Proc.new{|gene|
        gene + ((rand*1).round.eql?(1) ? 1 : -1)
      })
      assert_genes_increasing_in_value
    end
  
  end


  describe "tracking best so far" do 
    it 'should evolve a population' do 
      @ga = DarwinianProcess.new(:mutation_rate => 0.1, :mutation_function => :binary)
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

