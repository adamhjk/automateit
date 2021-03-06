require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

#===[ stub classes ]====================================================# {{{

#---[ MyBrokenManager ]-------------------------------------------------

class MyBrokenManager < AutomateIt::Plugin::Manager
  def mymethod(opts)
    dispatch(opts)
  end
end

class MyBrokenManager::BaseDriver < AutomateIt::Plugin::Driver
  # Is abstract by default
end

class MyBrokenManager::MyBrokenDriver < MyBrokenManager::BaseDriver
  def suitability(method, *args)
    return {:omfg => :lol}
  end
end

#---[ MyDriverlessManager ]---------------------------------------------

class MyDriverlessManager < AutomateIt::Plugin::Manager
  def mymethod(opts)
    dispatch(opts)
  end
end

#---[ MyManager ]-------------------------------------------------------

class MyManager < AutomateIt::Plugin::Manager
  alias_methods :mymethod

  def mymethod(opts)
    dispatch(opts)
  end

  def mynonexistentmethod(opts)
    dispatch_safely(opts)
  end
end

class MyManager::BaseDriver < AutomateIt::Plugin::Driver
  # Is abstract by default
end

class MyManager::AnotherBaseDriver < MyManager::BaseDriver
  abstract_driver
end

class MyManager::MyUnsuitableDriver < MyManager::BaseDriver
  # +suitability+ method deliberately not implemented to test errors

  depends_on \
    :files => ["non_existent_file"],
    :directories => ["non_existent_directory"],
    :programs => ["non_existent_program"]

  def unavailable_method
    _raise_unless_available
  end
end

class MyManager::MyUnimplementedDriver < MyManager::BaseDriver
  def available?
    true
  end

  def suitability(method, *args)
    return 50
  end

  # +mymethod+ method deliberately not implemented to test errors
end

class MyManager::MyInvalidDependsOnDriver < MyManager::BaseDriver
  depends_on nil
end

class MyManager::MyInvalidDependencyTypeDriver < MyManager::BaseDriver
  depends_on :omfg => :lol
end

class MyManager::MyNonexistentLibrariesDependencyDriver < MyManager::BaseDriver
  depends_on :libraries => %w(qjkwerlkjqweluxovxuqwe)
end

class MyManager::MyNonexistentProgramsDependencyDriver < MyManager::BaseDriver
  depends_on :programs => %(qlkjwesziuxkjlrjklqwel)
end

class MyManager::MyValidLibraryDependencyDriver < MyManager::BaseDriver
  depends_on :requires => %w(set)
end

class MyManager::MyFirstDriver < MyManager::BaseDriver
  depends_on :directories => ["/"]

  def suitability(method, *args)
    case method
    when :mymethod
      value = args.first ? args.first[:one] : nil
      return value == 1 ? 10 : 0
    else
      return -1
    end
  end

  def mymethod(opts)
    opts[:one]
  end
end

class MyManager::MySecondDriver < MyManager::BaseDriver
  def available?
    true
  end

  def suitability(method, *args)
    case method
    when :mymethod
      value = args.first ? args.first[:one] : nil
      return value == 1 ? 5 : 0
    else
      return -1
    end
  end

  def mymethod(opts)
    opts[:one]
  end
end

class MyManagerSubclass < AutomateIt::Plugin::Manager
  abstract_manager
end

class MyManagerSubclassImplementation < MyManagerSubclass
end
# }}}
#===[ rspec ]===========================================================

describe "AutomateIt::Plugin::Manager" do
  before(:all) do
    @x = AutomateIt::Plugin::Manager
  end

  it "should have plugins" do
    @x.classes.should include(MyManager)
  end

  it "should not have abstract plugins" do
    @x.classes.should_not include(MyManagerSubclass)
  end

  it "should have implementations of abstract plugins" do
    @x.classes.should include(MyManagerSubclassImplementation)
  end
end

describe "MyManager" do
  before(:all) do
    @m = MyManager.new
  end

  it "should have a class token" do
    MyManager.token.should == :my_manager
  end

  it "should have an instance token" do
    @m.token.should == :my_manager
  end

  it "should have drivers" do
    for driver in [MyManager::MyUnsuitableDriver, MyManager::MyFirstDriver, MyManager::MySecondDriver]
      @m.class.driver_classes.should include(driver)
    end
  end

  it "should inherit common instance mehtods" do
    @m.should respond_to(:log)
  end

  it "should access drivers by index keys" do
    @m[:my_first_driver].should be_a_kind_of(MyManager::MyFirstDriver)
    @m.drivers[:my_first_driver].should be_a_kind_of(MyManager::MyFirstDriver)
  end

  it "should have aliased methods" do
    @m.class.aliased_methods.should include(:mymethod)
  end

  it "should respond to aliased methods" do
    @m.should respond_to(:mymethod)
  end

  it "should have an interpreter instance" do
    @m.interpreter.should be_a_kind_of(AutomateIt::Interpreter)
  end

  # XXX Plugins spec -- Instantiating a Plugin outside of an Interpreter should retain consistent object references
#  it "should inject interpreter instance into drivers" do
#    @m.interpreter.object_id.should == m[:my_first_driver].interpreter.object_id
#  end
end

describe "MyManager's drivers" do
  before(:each) do
    @m = MyManager.new
  end

  it "should be available" do
    MyManager::MyFirstDriver.new.available?.should be_true
  end

  it "should fail on unavailable methods" do
    lambda{ MyManager::MyUnsuitableDriver.new.unavailable_method }.should
      raise_error(NotImplementedError, /non_existent/)
  end

  it "should not consider drivers that declare absurd dependencies to be available" do
    @m[:my_invalid_depends_on_driver].should_not be_available
  end

  it "should not consider drivers that depend on non-existent library dependencies to be available" do
    @m[:my_nonexistent_libraries_dependency_driver].should_not be_available
  end

  it "should not consider drivers that depend on non-existent program dependencies to be available" do
    @m[:my_nonexistent_programs_dependency_driver].should_not be_available
  end

  it "should figure out why drivers aren't available" do
    lambda {
      @m[:my_nonexistent_programs_dependency_driver].send(:_raise_unless_available)
    }.should raise_error(NotImplementedError, /Missing.+programs.+qlkjwesziuxkjlrjklqwel/)
  end

  it "should fail when drivers define unknown dependency types" do
    lambda { @m[:my_invalid_dependency_type_driver].available? }.should raise_error(TypeError)
  end

  it "should consider driver with valid library to be available" do
    @m[:my_valid_library_dependency_driver].available?.should be_true
  end

  it "should have a token" do
    MyManager::MyFirstDriver.token.should == :my_first_driver
  end

  it "should consider good drivers to be suitable" do
    MyManager::MyFirstDriver.new.suitability(:mymethod, :one => 1).should > 0
  end

  it "should not consider drivers that don't declare their suitability" do
    MyManager::MyUnsuitableDriver.new.suitability(:mymethod, :one => 1).should < 0
  end

  it "should determine suitability levels" do
    rs = @m.driver_suitability_levels_for(:mymethod, :one => 1)
    rs[:my_first_driver].should == 10
    rs[:my_second_driver].should == 5
    rs[:my_unsuitable_driver].should be_nil
  end

  it "should choose suitable driver" do
    @m.driver_for(:mymethod, :one => 1).should be_a_kind_of(MyManager::MyFirstDriver)
  end

  it "should not choose driver if none match" do
    lambda { @m.driver_for(:mymethod, :one => 9) }.should raise_error(NotImplementedError)
  end

  it "should claim availability for suitable method" do
    @m.available?(:mymethod, :one => 1).should be_true
  end

  it "should not claim availability of unsuitable method" do
    @m.available?(:mymethod, :one => 9).should be_false
  end

  it "should not claim availability of non-existent method" do
    @m.available?(:asdf).should be_false
  end

  it "should dispatch_to suitable driver" do
    @m.dispatch_to(:mymethod, :one => 1).should == 1
    @m.mymethod(:one => 1).should == 1
  end

  it "should fail dispatch_to if no suitable driver is found" do
    lambda { @m.dispatch_to(:mymethod, :one => 9) }.should raise_error(NotImplementedError)
    lambda { @m.mymethod(:one => 9) }.should raise_error(NotImplementedError)
  end

  it "should dispatch_to default driver regardless of suitability" do
    @m.default(:my_unimplemented_driver)
    lambda { @m.dispatch_to(:mymethod, :one => 1) }.should raise_error(NoMethodError)
    lambda { @m.mymethod(:one => 1) }.should raise_error(NoMethodError)
  end

  it "should dispatch_to default= driver regardless of suitability" do
    @m.default = :my_unimplemented_driver
    lambda { @m.dispatch_to(:mymethod, :one => 1) }.should raise_error(NoMethodError)
    lambda { @m.mymethod(:one => 1) }.should raise_error(NoMethodError)
  end

  it "should dispatch to a driver using :with option" do
    @m.mymethod(:one => 1, :with => :my_first_driver).should == 1
  end

  it "should dispatch safely" do
    @m.mynonexistentmethod(:hello => :world).should be_nil
  end

  it "should dispatch safely to non-suitable drivers" do
    @m.dispatch_safely_to(:asdf).should be_nil
  end

  it "should have an interpreter instance" do
    MyManager::MyFirstDriver.new.interpreter.should be_a_kind_of(AutomateIt::Interpreter)
  end

  it "should share object instances" do
    @m[:my_first_driver].should == @m.interpreter.my_manager[:my_first_driver]
  end

  it "should have a manager" do
    @m[:my_first_driver].manager.should == @m
  end

end

describe "MyBrokenManager" do
  before(:all) do
    @m = MyBrokenManager.new
  end

  it "should fail to find an invalid driver" do
    lambda { @m.driver_for(:mymethod) }.should raise_error(NotImplementedError)
  end
end

describe "MyDriverlessManager" do
  before(:all) do
    @m = MyDriverlessManager.new
  end

  it "should fail to find a driver for manager without drivers" do
    lambda { @m.driver_for(:mymethod) }.should raise_error(NotImplementedError)
  end
end

describe "MyManagerlessDriver" do
  it "should fail to create a driver without a manager" do
    lambda {
      self.class.module_eval do
        class MyManagerlessDriver < AutomateIt::Plugin::Driver
          # Will fail
        end
      end
    }.should raise_error(TypeError)
  end
end

describe AutomateIt::Interpreter do
  before(:all) do
    @a = AutomateIt::Interpreter.new
  end

  it "should instantiate plugins" do
    @a.should respond_to(:plugins)
    @a.plugins.keys.should include(:my_manager)
  end

  it "should expose plugin instance aliases" do
    @a.should respond_to(:my_manager)
    @a.my_manager.class.should == MyManager
  end

  it "should expose plugin method aliases" do
    @a.should respond_to(:mymethod)
    lambda {@a.mymethod(:one => 1)}.should_not raise_error
  end

  it "should inject itself into plugins" do
    @a.my_manager.interpreter.should == @a
  end

  it "should inject itself into drivers" do
    @a.my_manager[:my_first_driver].interpreter.should == @a
  end

  it "should not see abstract managers" do
    @a.plugins.keys.should_not include(MyManagerSubclass.token)
  end

  it "should not see abstract drivers" do
    @a.my_manager.drivers.keys.should_not include(MyManager::AnotherBaseDriver.token)
  end

  it "should not see base drivers" do
    @a.my_manager.drivers.keys.should_not include(MyManager::BaseDriver.token)
  end
end
