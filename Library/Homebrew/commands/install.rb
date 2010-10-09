def brew_install
  check_for_blacklisted_formula(ARGV.named)

  require 'hardware'

  case Hardware.cpu_type when :ppc, :dunno
    abort "Sorry, Homebrew does not support your computer's CPU architecture.\n"+
          "For PPC support, see: http://github.com/sceaga/homebrew/tree/powerpc"
  end

  raise "Cannot write to #{HOMEBREW_CELLAR}" if HOMEBREW_CELLAR.exist? and not HOMEBREW_CELLAR.writable?
  raise "Cannot write to #{HOMEBREW_PREFIX}" unless HOMEBREW_PREFIX.writable?

  begin
    if MACOS_VERSION >= 10.6
      if llvm_build < RECOMMENDED_LLVM
        opoo "You should upgrade to Xcode 3.2.3"
      end
    else
      if (gcc_40_build < RECOMMENDED_GCC_40) or (gcc_42_build < RECOMMENDED_GCC_42)
        opoo "You should upgrade to Xcode 3.1.4"
      end
    end
  rescue
    # the reason we don't abort is some formula don't require Xcode
    # TODO allow formula to declare themselves as "not needing Xcode"
    opoo "Xcode is not installed! Builds may fail!"
  end

  if macports_or_fink_installed?
    opoo "It appears you have MacPorts or Fink installed."
    puts "Software installed with MacPorts and Fink are known to cause problems."
    puts "If you experience issues try uninstalling these tools."
  end

  require 'formula_installer'

  installer = FormulaInstaller.new
  installer.install_deps = !ARGV.include?('--ignore-dependencies')

  ARGV.formulae.each do |f|
    if not f.installed? or ARGV.force?
      installer.install f
    else
      puts "Formula already installed: #{f.prefix}"
    end
  end
end
