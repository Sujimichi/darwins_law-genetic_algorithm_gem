require 'spec_helper'
require 'fileutils'

describe GeneticAlgorithm do

  describe "default initialize" do 
    
    it 'should have set a number of instance variables' do 
      @mga = GeneticAlgorithm.new
      vars = [:@popsize, :@gene_length, :@cross_over_rate, :@mutation_rate, :@mutation_type, :@generations, :@population, :@fitness_function]
      @mga.instance_variables.map{|v| vars.should be_include(v)}      
    end

  end

end
