require 'spec_helper'


describe EventOutput do
  before(:all) do 
    @newbest = EventOutput::NewBestStr
    @curbest = EventOutput::CurBestStr
  end

  describe "extending GeneticAlgorithm::Base with EventOutput" do 

    it 'should add show_breeding_event method to ga' do
      @ga = GeneticAlgorithm::Base.new
      @ga.should_not respond_to :show_breeding_event
      @ga.extend EventOutput
      @ga.should respond_to :show_breeding_event
    end

    it 'should extend ::Base with the EventOutput module when :show_breeding_event arg is given any non false value' do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true) 
      @ga.should respond_to :show_breeding_event

      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :each_time) 
      @ga.should respond_to :show_breeding_event

      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => false) 
      @ga.should_not respond_to :show_breeding_event
    end

    it 'should set the interval to show breeding event' do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :every_20) 
      @ga.interval_for[:breeding_event].should == 20

      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :every_50) 
      @ga.interval_for[:breeding_event].should == 50

      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :each_time) 
      @ga.interval_for[:breeding_event].should == 1
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true) 
      @ga.interval_for[:breeding_event].should == 1

      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => :with_best)
      @ga.interval_for[:breeding_event].should == :with_best

    end
  end


  describe "showing breeding event" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true) 
      @ga.verbose.should be_true
    end

    it 'should call show_breeding_event on each single_generation (with interval 1)' do 
      @ga.interval_for[:breeding_event].should == 1
      @ga.should_receive(:show_breeding_event).exactly(30).times
      @ga.evolve(30)
    end 

    it 'should call show_breeding_event on each 10th single_generation (with interval 10)' do 
      @ga.interval_for[:breeding_event] = 10
      @ga.should_receive(:show_breeding_event).exactly(3).times
      @ga.evolve(30)
    end

  end

  describe "breeding event" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true)
      @ga.instance_variable_set("@best", {:genome => [0,0,0,0,0,0,1,1,0,0], :fitness => 50})#not a real fitness, just stops being marked as best as this is not what is being tested here.
    end
    
    it 'should show the parents and offspring genomes' do 
      @ga.stub!(:from_population => [[1,1,1,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,0,0,0]])
      @ga.stub!(:recombine => [0,1,0,1,0,1,0,1,0,1])
      
      @ga.should_receive(:puts).with([
        "1111111111--\\",
        "             }>----------0101010101", 
        "0000000000--/", 
        "\n\n"
      ]) 
      @ga.single_generation
    end

    it 'should show long genomes as hexi-digested strings' do 
      p1,p2 = [Array.new(40){1},Array.new(40){0}]
      offs = Array.new(40){0.5}
      @ga.stub!(:from_population => [p1,p2])
      @ga.stub!(:recombine => offs)     
      @ga.should_receive(:puts).with([
        "1a4d9d267d29e7c3582a8735a57eb43a--\\",
        "                                   }>----------6309e2e30189e9e556ca7e6de0402861", 
        "b373e3ddc3438d7c10c76f3ad9d4c401--/", 
        "\n\n"
      ]) 
      @ga.single_generation
    end


    describe "counting mutations" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true)
        @ga.instance_variable_set("@best", {:genome => [0,0,0,0,0,0,1,1,0,0], :fitness => 12})#not a real fitness, just stops being marked as best as this is not what is being tested here.
      end

      it 'should count the number of mutations which occured' do
        @ga.instance_variable_get("@mut_count").should be_nil
        @ga.should_receive(:puts).exactly(3).times.and_return(nil) #just to mask output being shown in testrun.

        Kernel.stub!(:rand).and_return(1)
        @ga.single_generation
        @ga.instance_variable_get("@mut_count").should == 0

        Kernel.stub!(:rand).and_return(*[1,1,1,0,1])
        @ga.single_generation
        @ga.instance_variable_get("@mut_count").should == 1

        Kernel.stub!(:rand).and_return(1)
        @ga.single_generation
        @ga.instance_variable_get("@mut_count").should == 0
   
      end
      
      it 'should show number of mutations' do 
        @ga.stub!(:from_population => [[1,1,1,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,0,0,0]])
        #@ga.stub!(:recombine => [0,1,0,1,0,1,0,1,0,1])
        @ga.instance_variable_set("@mut_count", 2)
        @ga.mutation_function = Proc.new{|g| g}

        Kernel.stub!(:rand).and_return(*[1,1,1,0,1,0,1,1,0,1,0,1])
      
        @ga.should_receive(:puts).with([
          "1111111111--\\",
          "             }>-Mutant(2)-0000110000", 
          "0000000000--/", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

    end

    describe "showing fitness values when cache is present" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true)
        @ga.extend(FitnessCaching)
        @ga.stub!(:fitness_of) #stops real caching getting in the way of stubbed cache values
        @ga.stub!(:from_population => [[1,1,1,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,0,0,0]])
        @ga.stub!(:recombine => [0,1,0,1,0,1,0,1,0,1])

        @ga.instance_variable_set("@best", {:genome => [0,0,0,0,0,0,1,1,0,0], :fitness => 12})#not a real fitness, just stops being marked as best as this is not what is being tested here.
        
      end
      
      it 'should show fitness of parents' do 
        @ga.instance_variable_set("@cache", {[1,1,1,1,1,1,1,1,1,1] => 10, [0,0,0,0,0,0,0,0,0,0] => 0})
        
        @ga.should_receive(:puts).with([
          "1111111111--\\ <= 10.0",
          "             }>----------0101010101", 
          "0000000000--/ <= 0.0", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

      it 'should show fitness of parents and offspring if offspirng has already been encouterd' do 
        @ga.instance_variable_set("@cache", {[1,1,1,1,1,1,1,1,1,1] => 10, [0,0,0,0,0,0,0,0,0,0] => 0, [0,1,0,1,0,1,0,1,0,1] => 5})
        
        @ga.should_receive(:puts).with([
          "1111111111--\\ <= 10.0",
          "             }>----------0101010101 <= 5.0", 
          "0000000000--/ <= 0.0", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

    end


    describe "marking current best (without cached fitness values)" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true)
      end

      it 'should mark current best on parent 1' do
        @ga.stub!(:from_population => [[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0]])
        @ga.stub!(:recombine => [0,1,0,1,0,0,0,0,0,0])

        @ga.should_receive(:puts).with([
          "1111100000--\\ <= #{@curbest}",
          "             }>----------0101000000", 
          "0000000000--/", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

      it 'should mark current best on parent 2' do
        @ga.stub!(:from_population => [[0,0,0,0,0,0,0,0,0,0], [1,1,1,1,1,0,0,0,0,0]])
        @ga.stub!(:recombine => [0,1,0,1,0,0,0,0,0,0])

        @ga.should_receive(:puts).with([
          "0000000000--\\",
          "             }>----------0101000000", 
          "1111100000--/ <= #{@curbest}", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

      it 'should show best so far on offspring' do 
        @ga.stub!(:from_population => [[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,1,1,1,1,1]])
        @ga.should_receive(:from_population).ordered.and_return([[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,1,1,1,1,1]])
        @ga.should_receive(:from_population).ordered.and_return([[1,1,1,1,1,1,1,1,1,1]])
        @ga.mutation_function = Proc.new{|g| (g-1).abs }
        Kernel.stub!(:rand).and_return(*[0])
        Kernel.stub!(:rand).and_return(*[0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1])

        @ga.should_receive(:puts).with([
          "1111100000--\\",
          "             }>----------1111111111 <= *", 
          "0000011111--/", 
          "\n\n"
        ])
        @ga.single_generation
      end      

    end


    describe "marking current best (with cached fitness values)" do 
      before(:each) do 
        @ga = GeneticAlgorithm::Base.new(:show_breeding_event => true, :verbose => true)
        @ga.extend FitnessCaching
        @ga.stub!(:fitness_of) #stops real caching getting in the way of stubbed cache values
        @ga.instance_variable_set("@cache", {[1,1,1,1,1,0,0,0,0,0] => 5, [1,1,1,1,1,1,1,1,1,1] => 10, [0,0,0,0,0,0,0,0,0,0] => 0})
      end

      it 'should mark current best on parent 1' do
        @ga.stub!(:from_population => [[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0]])
        @ga.stub!(:recombine => [0,1,0,1,0,0,0,0,0,0])
        @ga.instance_variable_set("@best", {:genome => [1,1,1,1,1,0,0,0,0,0], :fitness => 5})      

        @ga.should_receive(:puts).with([
          "1111100000--\\ <= 5.0#{@curbest}",
          "             }>----------0101000000", 
          "0000000000--/ <= 0.0", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

      it 'should mark current best on parent 2' do
        @ga.stub!(:from_population => [[0,0,0,0,0,0,0,0,0,0], [1,1,1,1,1,0,0,0,0,0]])
        @ga.stub!(:recombine => [0,1,0,1,0,0,0,0,0,0])
        @ga.instance_variable_set("@best", {:genome => [1,1,1,1,1,0,0,0,0,0], :fitness => 5})      

        @ga.should_receive(:puts).with([
          "0000000000--\\ <= 0.0",
          "             }>----------0101000000", 
          "1111100000--/ <= 5.0#{@curbest}", 
          "\n\n"
        ]) 
        @ga.single_generation
      end

      it 'should show best so far on offspring' do 
        @ga.stub!(:from_population => [[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,1,1,1,1,1]])
        @ga.should_receive(:from_population).ordered.and_return([[1,1,1,1,1,0,0,0,0,0],[0,0,0,0,0,1,1,1,1,1]])
        @ga.should_receive(:from_population).ordered.and_return([[1,1,1,1,1,1,1,1,1,1]])
        @ga.mutation_function = Proc.new{|g| (g-1).abs }
        @ga.instance_variable_set("@best", {:genome => [1,1,1,1,1,1,1,1,1,1], :fitness => 10})
        Kernel.stub!(:rand).and_return(*[0])
        Kernel.stub!(:rand).and_return(*[0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1])

        @ga.should_receive(:puts).with([
          "1111100000--\\ <= 5.0",
          "             }>----------1111111111 <= 10.0*", 
          "0000011111--/", 
          "\n\n"
        ])
        @ga.single_generation
      end      

    end
  end

end
