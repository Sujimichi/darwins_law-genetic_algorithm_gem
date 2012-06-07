require 'spec_helper'

describe ConvergenceMonitor do

  describe "calculating convergence" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true, :init_pop_with => 0)
      @ga.extend ConvergenceMonitor
    end
    it 'should return convergence level of population' do 
      @ga.population = Array.new(25){Array.new(5){0}} #all members the same 100% converged
      @ga.current_convergence.should == 1
    
      i = 0
      @ga.population = Array.new(42){Array.new(5){i+=1}} #all members different 0% converged
      @ga.current_convergence.round(1).should == 0.0

      p = []
      Array.new(5){Array.new(5){0}}.each{|m| p << m}
      Array.new(5){Array.new(5){1}}.each{|m| p << m}
      @ga.population = p #half members the same 50% converged
      
      @ga.current_convergence.should == 0.5
    end
  end

  describe "output" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true, :init_pop_with => 0)
      @ga.extend ConvergenceMonitor
    end

    it 'should output the current convergence as percentage' do 
      @ga.should_receive(:puts).with("Population is 30.0% converged")
      @ga.stub!(:current_convergence => 0.3)
      @ga.show_current_convergence :as_percent
    end

    it 'should output the current convergence as percentage bar' do 
      @ga.stub!(:convergence => [[1,5], [2,4], [3,3], [4,2], [5,2], [6,3], [7,4], [8,5], [9,6], [10,7]])

      @ga.instance_variable_set("@current_generation", 0)
      @ga.stub!(:current_convergence => 0)
      @ga.should_receive(:puts).with(  "     0 |                                                  |0.0%" )
      @ga.show_current_convergence :as_percent_bar
      
      @ga.instance_variable_set("@current_generation", 20)
      @ga.stub!(:current_convergence => 0.25)
      @ga.should_receive(:puts).with(  "    20 |=============                                     |25.0%" )
      @ga.show_current_convergence :as_percent_bar


      @ga.instance_variable_set("@current_generation", 30)
      @ga.stub!(:current_convergence => 0.23)
      @ga.should_receive(:puts).with(  "    30 |============                                      |23.0%" )
      @ga.show_current_convergence :as_percent_bar
      

      @ga.instance_variable_set("@current_generation", 400)
      @ga.stub!(:current_convergence => 1.0)
      @ga.should_receive(:puts).with(  "   400 |==================================================|100.0%" )
      @ga.show_current_convergence :as_percent_bar

    end
    
    it 'should output the current convergence as a graph(of sorts)' #do 
=begin
      @ga.stub!(:convergence => [[1,5], [2,4], [3,3], [4,2], [5,2], [6,3], [7,4], [8,5], [9,6], [10,7]])

      @ga.should_receive(:puts).with([
        " 7|                           #",
        " 6|                        #",
        " 5|#                    #",
        " 4|   #              #",
        " 3|      #        #",
        " 2|         #  #",
        " 1|",
        " 0|_____________________________",
        "   1  2  3  4  5  6  7  8  9  10"
      ])

      @ga.show_current_convergence :as_graph

    end
=end


  end

end
