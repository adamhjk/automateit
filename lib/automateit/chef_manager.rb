# == ChefManager
#
# Provides access to Chef resources
#
module AutomateIt
  class ChefManager < Plugin::Manager

    # Runs the recipe passed as a block
    def recipe(*arguments, &block) 
      dispatch(*arguments, &block) 
    end

    # == ChefManager::BaseDriver
    #
    # Base class for all ChefManager drivers.
    class BaseDriver < Plugin::Driver
    end

    # == ChefManager::Recipe
    #
    class Recipe < BaseDriver
      depends_on :libraries => %w(chef chef/runner)

      def suitability(method, *args) # :nodoc:
        return available? ? 1 : 0
      end

      def recipe(*arguments, &block)
        Chef::Log.logger = log
        node = Chef::Node.new
        om = AutomateIt::OhaiManager.new
        om.ohai.each do |f, v|
          node[f] = v
        end
        recipe = Chef::Recipe.new(:automateit, :default, node)
        recipe.instance_eval(&block)
        runner = Chef::Runner.new(node, recipe.collection)
        runner.converge
      end

    end
  end
end
