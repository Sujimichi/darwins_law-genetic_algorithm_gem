require 'spec_helper'
require 'fileutils'


describe DarwinianProcess do
  before(:each) do 
    @darwin = DarwinianProcess.new
    @darwin.gene_length = 10    
  end

  describe "selection" do 
    before(:each) do 
      i=0
      @pop = Array.new(10){i+=1} 
      @darwin.instance_variable_set("@population", @pop)
      #Kernel.stub!(:rand).and_return(*[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])
    end
    it 'should return two members from the population' do 
      @darwin.select_pair.should be_a(Array)
      @darwin.select_pair.each{|selected| @pop.should be_include(selected)}
    end
    it 'should not return the same two members' do 
      200.times{
        pair = @darwin.select_pair
        pair.first.should_not == pair.last
      }
    end
    
    it 'should return a sorted pair (fittest first)' do 
      @darwin.stub!(:fitness_of).and_return(*[4,5])
      @darwin.stub!(:select_pair => [[1,1,1,1,0],[1,1,1,1,1]])
      pair = @darwin.select_sorted_pair
      pair.should == [[1,1,1,1,1],[1,1,1,1,0]]
    end

  end
  
  describe "recombination" do 
    before(:each) do
      @parent1 = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      @parent2 = [-1,-2,-3,-4,-5,-6,-7,-8,-9,-10]
      Kernel.stub!(:rand).and_return(*[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])


      @darwin.should_receive(:apply_possible_muation).and_yield().any_number_of_times


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
  end

  describe "fitness evaluation" do 
    it 'should have some tests'
  end
  

end
