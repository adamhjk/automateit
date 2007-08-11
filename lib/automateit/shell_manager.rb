require 'automateit'
require 'open3'

module AutomateIt
  class ShellManager < Plugin::Manager
    alias_methods :sh, :which, :ln, :ln_s, :ln_sF, :rm, :rm_r, :rm_rF, :rmdir, :cp, :cp_R, :mv, :touch, :chmod, :chmod_R, :chown, :chown_R, :own

    def sh(*args) dispatch(*args) end

    def which(command) dispatch(command) end

    class POSIX < Plugin::Driver
      def suitability(method, *args)
        return 3 # TODO how do I know if this has posix?
      end

      def sh(*args)
        interpreter.logger.info("$$$ #{args.join(' ')}")
        return system(*args) if interpreter.writing?
      end

      def which(command)
        return Open3.popen3("which", command) do |sin, sout, serr|
          data = sout.read.chomp
          data if File.exists?(data)
        end
      end
    end
  end
end
