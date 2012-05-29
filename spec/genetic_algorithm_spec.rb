require 'spec_helper'
require 'fileutils'

describe GeneticAlgorithm do

  describe "default initialize" do 
    
    it 'should have set a number of instance variables' do 
      @ga = GeneticAlgorithm.new
      vars = [:@popsize, :@gene_length, :@cross_over_rate, :@mutation_rate, :@generations, :@population, :@mutation_function, :@fitness_function]
      @ga.instance_variables.map{|v| vars.should be_include(v)}      
    end

  end


  describe "simple evolution" do 

    it 'should increase sum of genomes with summation fitness func' do 
      @ga = GeneticAlgorithm.new(:generations => 100, :gene_length => 4, :fitness_function => Proc.new{|genome|
        genome.inject{|i,j| i+j}
      })
      sum = @ga.population.flatten.inject{|i,j| i+j}
      @ga.evolve
      sum2 = @ga.population.flatten.inject{|i,j| i+j}
      sum.should_not == sum2
      sum2.should > sum
    end

    it 'should descrease sum of genomes with subtraction fitness func' do 
      @ga = GeneticAlgorithm.new(:generations => 100, :gene_length => 4, :fitness_function => Proc.new{|genome|
        genome.inject{|i,j| i - j}
      })
      sum = @ga.population.flatten.inject{|i,j| i+j}
      @ga.evolve
      sum2 = @ga.population.flatten.inject{|i,j| i+j}
      sum.should_not == sum2
      sum2.should < sum
    end

  end

  describe "custom evolution" do 

    it 'should run evolution with custom functions' do 
      @ga = GeneticAlgorithm.new(
        :generations => 10000, 
        :gene_length => 4, 
        :mutation_rate => 0.3,
        :init_pop_with    => Proc.new{ (10 * rand) - 5 },
        :fitness_function => Proc.new{|genome| 0 - (0 - genome.inject{|i,j| i + j}).abs },
        :mutation_function=> Proc.new{|gene| (gene + (rand - 0.5)) }
      )
      @ga.population.flatten.max.should > 4.2
      @ga.population.flatten.min.should < -4.2
      @ga.evolve
      @ga.population.flatten.max.should > 1.2
      @ga.population.flatten.min.should < -1.2
    end

  end


  describe "population initialization" do 

    it 'should initialize population with all 0s' do 
      @ga = GeneticAlgorithm.new(:gene_length => 4, :popsize => 10, :init_pop_with => 0)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should initialize population with all 1s' do 
      @ga = GeneticAlgorithm.new(:gene_length => 4, :popsize => 10, :init_pop_with => 1)
      @ga.population.should == Array.new(10){Array.new(4){1}}
      @ga.population.uniq.size.should == 1
    end
    it 'should initialize population with all rand ' do      
      @ga = GeneticAlgorithm.new(:gene_length => 4, :popsize => 10, :init_pop_with => :rand)
      @ga.population.uniq.size.should == 10
    end
    it 'should initialize population with all 0 by default' do      
      @ga = GeneticAlgorithm.new(:gene_length => 4, :popsize => 10)
      @ga.population.should == Array.new(10){Array.new(4){0}}
    end
    it 'should be initialized with custom population' do 
      @ga = GeneticAlgorithm.new(:population => [[0,0,0], [0,0,0]])
      @ga.population.should == [[0,0,0], [0,0,0]]
      @ga.popsize.should == 2
      @ga.gene_length.should == 3
    end
    it 'should throw error if genomes are different size' do 
      t = false
      begin
      @ga = GeneticAlgorithm.new(:population => [[0,0,0], [0,0,0,1]])
      rescue
        t = true
      end
      t.should be_true
    end

  end

  describe "fitness function" do 

    it 'should have a default max_ones fitness function' do 
      @ga = GeneticAlgorithm.new
      @ga.fitness_of([1,1,1,1,1]).should == 5
      @ga.fitness_of([2,1,0,1,2]).should == 6
    end
    it 'should take a custom fitness function' do 
      @ga = GeneticAlgorithm.new(:fitness => Proc.new{|genome| genome.inject{|i,j| i-j} })
      @ga.fitness_of([1,1,1,1,1]).should == -3
      @ga.fitness_of([1,-1,1,-1,1]).should == 1    
    end

  end

  describe "mutation function" do 

    it 'should have a default :decimal mutation function ' do 
      @ga = GeneticAlgorithm.new(:mutation_rate => 10, :gene_length => 10) #config for mutation of every gene
      @ga.pos_mutate(4).should_not == 4
      (@ga.pos_mutate(4) >= 3.5 && @ga.pos_mutate(4) <= 4.5).should be_true
    end

    it 'should have option for :binary mutation function ' do 
      @ga = GeneticAlgorithm.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => :binary) #config for mutation of every gene
      @ga.pos_mutate(0).should == 1
      @ga.pos_mutate(1).should == 0
    end

    it 'should have option for :binary mutation function ' do 
      @ga = GeneticAlgorithm.new(:mutation_rate => 10, :gene_length => 10, :mutation_function => Proc.new{|gene| gene+2}) #config for mutation of every gene
      @ga.pos_mutate(3).should == 5
      @ga.pos_mutate(1).should == 3
    end

  end

end
