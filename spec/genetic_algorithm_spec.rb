require 'spec_helper'
require 'fileutils'


describe GeneticAlgorithm do

  describe "default initialize" do 
    
    it 'should have set a number of instance variables' do 
      @ga = GeneticAlgorithm.new
      vars = [:@popsize, :@gene_length, :@cross_over_rate, :@mutation_rate, :@generations, :@population, :@mutation_function, :@fitness_function]
      i_vars = @ga.instance_variables
      vars.map{|v| i_vars.should be_include(v)}      
    end

  end


  describe "default evolution" do 

    it 'should increase sum of genomes with summation fitness func' do 
      @ga = GeneticAlgorithm.new(:generations => 200, :gene_length => 4)
      sum = @ga.population.flatten.inject{|i,j| i+j}
      @ga.evolve
      sum2 = @ga.population.flatten.inject{|i,j| i+j}
      sum.should_not == sum2
      sum2.should > sum
    end

    it 'should descrease sum of genomes with subtraction fitness func' do 
      @ga = GeneticAlgorithm.new(:generations => 200, :gene_length => 4, :fitness_function => Proc.new{|genome|   genome.inject{|i,j| i - j} })
      sum = @ga.population.flatten.inject{|i,j| i+j}
      @ga.evolve
      sum2 = @ga.population.flatten.inject{|i,j| i+j}
      sum.should_not == sum2
      sum2.should < sum
    end

  end

  describe "customized evolution" do 

    it 'should run evolution with custom functions' do 
      @ga = GeneticAlgorithm.new(
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



  describe "caching geneme fitness" do 

    it 'should cache a genomes fitness against a record of that genome' do
      @ga = GeneticAlgorithm.new(:cache_fitness => true)
      @ga.cache.should be_empty
      fitness = @ga.fitness_of([1,1,1,1])
      @ga.cache[[1,1,1,1]].should == fitness
    end

    it 'should return different values for different genomes' do 
      @ga = GeneticAlgorithm.new(:cache_fitness => true)     
      g1 = Array.new(150){rand}
      g2 = Array.new(150){rand}

      f1 = @ga.fitness_of g1
      f2 = @ga.fitness_of g2
      
      @ga.cache.keys.size.should == 2
      @ga.cache[g1].should == f1

    end
    it 'should return nil when a tiny change has been made to the genome' do 
      @ga = GeneticAlgorithm.new(:cache_fitness => true)     
      g1 = Array.new(150){rand}
      f1 = @ga.fitness_of g1
      g1[(rand*149).round] += 0.000000000001
      @ga.cache[g1].should be_nil
    end

  end


  describe "evolving a population" do 

    it 'should evolve a population' do 
      @ga = GeneticAlgorithm.new(:popsize => 20, :gene_length => 5, :init_pop_with => :rand, :mutation_rate => 0.3, :mutation_function => Proc.new{|gene|
        gene + ((rand*1).round.eql?(1) ? 1 : -1)
      })
      assert_genes_increasing_in_value
    end
  
  end

end
