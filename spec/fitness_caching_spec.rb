require 'spec_helper'

describe FitnessCaching do 

  describe "extending GeneticAlgorithm::Base with FitnessCaching" do 

    it 'should cache a genomes fitness against a record of that genome' do
      @ga = GeneticAlgorithm::Base.new
      @ga.extend FitnessCaching

      @ga.cache.should be_empty
      fitness = @ga.fitness_of([1,1,1,1])
      @ga.cache[[1,1,1,1]].should == fitness
    end

    it 'should extend ::Base with the caching module when the :cache_fitness arg is set to true' do
      @ga = GeneticAlgorithm::Base.new(:cache_fitness => false)
      @ga.should_not respond_to :cache
      @ga = GeneticAlgorithm::Base.new(:cache_fitness => true)
      @ga.should respond_to :cache
    end
  end


  describe "fitness caching" do 
    before(:each) do 
      @ga = GeneticAlgorithm::Base.new
      @ga.extend FitnessCaching
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

  end
  
  describe "comparison" do 

    #with init_pop_with => :rand should be about twice as fast over first few gens.
    #with init_pop_with => 0 (pop are all clones to start) it is about 9-10 times faster.
    it 'GA should run faster with caching than without' do 
      @ga_n = GeneticAlgorithm::Base.new(:init_pop_with => 0, :generations => 100, :fitness => Proc.new{|g| 
        sleep(0.05)
        g.inject{|i,j| i+j }
      })
      @ga_c = @ga_n.clone
      @ga_c.extend FitnessCaching

      time_without_cache = Timer.time_code { @ga_n.evolve }
      time_with_cache = Timer.time_code {    @ga_c.evolve }       
      #puts [time_without_cache, time_with_cache].inspect
      time_with_cache.should < (time_without_cache/2)
    end

  end
 
end


class Timer

  def self.time_code &blk
    t1 = Time.now
    yield
    t2 = Time.now
    t2-t1
  end

end




