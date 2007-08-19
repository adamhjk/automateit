require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check in #{__FILE__}"
else
  begin
    # This line will trigger a NotImplementedError that's caught at the bottom
    INTERPRETER.package_manager.driver_for(:installed?, "foo")

    describe "AutomateIt::PackageManager" do
      before(:all) do
        #@a = AutomateIt.new(:verbosity => Logger::DEBUG)
        @a = AutomateIt.new(:verbosity => Logger::WARN)
        @m = @a.package_manager

        # Find a small package with few dependencies, no dependants, no daemons
        # and little chance of it being in-use during the test.
        @package = @a.instance_eval do
          if tagged?("ubuntu || debian || fedoracore || redhat || centos")
            # Package for extracting ARC files from the early 80's
            "nomarch"
          else
            raise NotImplementedError.new("no testable package for this platform")
          end
        end
        # A package we don't expect to find.
        @fake_package = "not_a_real_package"

        if @m.installed?(@package, :quiet => true)
          raise "ERROR: Found the '#{@package}' installed! You're probably not using this obscure package and should remove it so the test can run. In the unlikely event that you actually rely on this package, change the spec to test another unused package."
        end
      end

      after(:all) do
        @m.uninstall(@package, :quiet => true)
      end

      # Some specs below leave side-effects which others depend on, although
      # these are clearly documented within the specs. This is necessary
      # because doing proper setup/teardown for each test would make it run 5x
      # slower and take over a minute. Although this approach is problematic,
      # the performance boost is worth it.

      it "should not install an invalid package" do
        lambda{ @m.install(@fake_package, :quiet => true) }.should raise_error(ArgumentError)
      end

      it "should install a package" do
        @m.install(@package, :quiet => true).should be_true
        # Leaves behind an installed package
      end

      it "should not re-install an installed package" do
        # Expects package to be installed
        @m.install(@package, :quiet => true).should be_false
      end

      it "should find an installed package" do
        # Expects package to be installed
        @m.installed?(@package).should be_true
        @m.not_installed?(@package).should be_false
      end

      it "should not find a package that's not installed" do
        @m.installed?(@fake_package).should be_false
        @m.not_installed?(@fake_package).should be_true
      end

      it "should find group of packages" do
        @m.installed?(@package, @fake_package, :list => true).should == [@package]
        @m.not_installed?(@package, @fake_package, :list => true).should == [@fake_package]
        # Leaves behind an installed package
      end

      it "should uninstall a package" do
        # Expects package to be installed
        @m.uninstall(@package, :quiet => true).should be_true
      end

      it "should not uninstall a package that's not installed" do
        @m.uninstall(@package, :quiet => true).should be_false
      end
    end
  rescue NotImplementedError
    puts "NOTE: This platform can't check #{__FILE__}"
  end
end
