# == PackageManager::PEAR
#
# A PackageManager driver for PEAR (PHP Extension and Application Repository),
# manages software packages using the <tt>pear</tt> command.
#
# === Using specific channels
#
# To install a package from the default PEAR channel, just specify it's name,
# e.g. <tt>HTML_QuickForm</tt>.
#
# To install a package from another channel, you must specify the name prefixed
# with the channel's URL, e.g. <tt>pear.symfony-project.com/symfony</tt>, so
# that the channel can be automatically added as needed.
#
# *IMPORTANT*: DO NOT specify a remote channel's alias, e.g.
# <tt>symfony/symfony</tt>, because this provides no way to discover the
# channel.
class ::AutomateIt::PackageManager::PEAR < ::AutomateIt::PackageManager::BaseDriver
  depends_on :programs => %w(pear)

  def suitability(method, *args) # :nodoc:
    # Never select as default driver
    return 0
  end

  # Retrieve a hash containing all installed packages, indexed by package
  # name.  Each value is a hash containing values for :version and :state.
  def get_installed_packages()
    cmd = "pear list --allchannels 2>&1"
    data = `#{cmd}`
    installed_packages = {}
    data.scan(/^([^(\s]+)\s+([^\s]+)\s+([^\s]+)$/) do |package, version, state|
      next if version.upcase == 'VERSION'
      installed_packages[package] = {:version => version, :state => state}
    end
    return installed_packages
  end
  protected :get_installed_packages

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      all_installed = get_installed_packages().keys.collect {|pkg| pkg.downcase}

      result = []
      list.each do |pkg|
        pkg_without_channel = pkg.gsub(%r{^[^/]+/}, '').downcase
        result.push pkg if all_installed.include?(pkg_without_channel)
      end

      result
    end
  end

  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    return _not_installed_helper?(*packages)
  end

  # *IMPORTANT*: See documentation at the top of this file for how to correctly
  # install packages from a specific channel.
  #
  # Options:
  # * :force -- Force installation, needed when installing unstable packages
  #
  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      # pear options:
      # -a install all required dependencies
      # -f force installation

      cmd = "(pear config-set auto_discover 1; "
      cmd << "pear install -a"
      cmd << " -f" if opts[:force]
      cmd << " "+list.join(" ")+" < /dev/null)"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|

      cmd = "pear uninstall "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
