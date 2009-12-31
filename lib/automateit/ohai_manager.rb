# == OhaiManager
#
# Provides access to Ohai data 
#
module AutomateIt
  class OhaiManager < Plugin::Manager
    alias_methods :ohai

    # Runs the recipe passed as a block
    def ohai(*arguments) dispatch_to(:data, *arguments) end

    alias_method :data, :ohai

    # == OhaiManager::BaseDriver
    #
    # Base class for all ChefManager drivers.
    class BaseDriver < Plugin::Driver
    end

    # == OhaiManager::Ohai
    #
    class Recipe < BaseDriver
      depends_on :libraries => %w(ohai)

      @@ohai = nil 

      def suitability(method, *args) # :nodoc:
        return available? ? 1 : 0
      end

      def data(*arguments)
        unless @@ohai
          Ohai::Log.logger = log
          @@ohai = Ohai::System.new
          @@ohai.all_plugins
        end
        @@ohai
      end

    end
  end
end
