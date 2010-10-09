FORMULA_META_FILES = %w[README README.md ChangeLog COPYING LICENSE LICENCE COPYRIGHT AUTHORS]
PLEASE_REPORT_BUG = "#{Tty.white}Please report this bug at #{Tty.em}http://github.com/mxcl/homebrew/issues#{Tty.reset}"

def check_for_blacklisted_formula names
  return if ARGV.force?

  names.each do |name|
    case name
    when 'tex', 'tex-live', 'texlive' then abort <<-EOS.undent
      Installing TeX from source is weird and gross, requires a lot of patches,
      and only builds 32-bit (and thus can't use Homebrew deps on Snow Leopard.)

      We recommend using a MacTeX distribution:
        http://www.tug.org/mactex/
    EOS

    when 'mercurial', 'hg' then abort <<-EOS.undent
      Mercurial can be install thusly:
        brew install pip && pip install mercurial
    EOS

    when 'setuptools' then abort <<-EOS.undent
      When working with a Homebrew-built Python, distribute is preferred
      over setuptools, and can be used as the prerequisite for pip.

      Install distribute using:
        brew install distribute
    EOS
    end
  end
end

def github_info name
  formula_name = Formula.path(name).basename
  user = 'mxcl'
  branch = 'master'

  if system "/usr/bin/which -s git"
    gh_user=`git config --global github.user 2>/dev/null`.chomp
    /^\*\s*(.*)/.match(`git --work-tree=#{HOMEBREW_REPOSITORY} branch 2>/dev/null`)
    unless $1.nil? || $1.empty? || gh_user.empty?
      branch = $1.chomp
      user = gh_user
    end
  end

  return "http://github.com/#{user}/homebrew/commits/#{branch}/Library/Formula/#{formula_name}"
end

def info f
  exec 'open', github_info(f.name) if ARGV.flag? '--github'

  puts "#{f.name} #{f.version}"
  puts f.homepage

  puts "Depends on: #{f.deps.join(', ')}" unless f.deps.empty?

  if f.prefix.parent.directory?
    kids=f.prefix.parent.children
    kids.each do |keg|
      next if keg.basename.to_s == '.DS_Store'
      print "#{keg} (#{keg.abv})"
      print " *" if f.installed_prefix == keg and kids.length > 1
      puts
    end
  else
    puts "Not installed"
  end

  if f.caveats
    puts
    puts f.caveats
    puts
  end

  history = github_info(f.name)
  puts history if history

rescue FormulaUnavailableError
  # check for DIY installation
  d=HOMEBREW_PREFIX+name
  if d.directory?
    ohai "DIY Installation"
    d.children.each {|keg| puts "#{keg} (#{keg.abv})"}
  else
    raise "No such formula or keg"
  end
end

def issues_for_formula name
  # bit basic as depends on the issue at github having the exact name of the
  # formula in it. Which for stuff like objective-caml is unlikely. So we
  # really should search for aliases too.

  name = f.name if Formula === name

  require 'open-uri'
  require 'yaml'

  issues = []

  open("http://github.com/api/v2/yaml/issues/search/mxcl/homebrew/open/"+name) do |f|
    YAML::load(f.read)['issues'].each do |issue|
      issues << 'http://github.com/mxcl/homebrew/issues/#issue/%s' % issue['number']
    end
  end

  issues
rescue
  []
end

def clean f
  require 'cleaner'
  Cleaner.new f
 
  # Hunt for empty folders and nuke them unless they are
  # protected by f.skip_clean?
  # We want post-order traversal, so put the dirs in a stack
  # and then pop them off later.
  paths = []
  f.prefix.find do |path|
    paths << path if path.directory?
  end

  until paths.empty? do
    d = paths.pop
    if d.children.empty? and not f.skip_clean? d
      puts "rmdir: #{d} (empty)" if ARGV.verbose?
      d.rmdir
    end
  end
end

def diy
  path=Pathname.getwd

  if ARGV.include? '--set-version'
    version=ARGV.next
  else
    version=path.version
    raise "Couldn't determine version, try --set-version" if version.to_s.empty?
  end
  
  if ARGV.include? '--set-name'
    name=ARGV.next
  else
    path.basename.to_s =~ /(.*?)-?#{version}/
    if $1.nil? or $1.empty?
      name=path.basename
    else
      name=$1
    end
  end

  prefix=HOMEBREW_CELLAR+name+version

  if File.file? 'CMakeLists.txt'
    "-DCMAKE_INSTALL_PREFIX=#{prefix}"
  elsif File.file? 'Makefile.am'
    "--prefix=#{prefix}"
  else
    raise "Couldn't determine build system"
  end
end

def macports_or_fink_installed?
  # See these issues for some history:
  # http://github.com/mxcl/homebrew/issues/#issue/13
  # http://github.com/mxcl/homebrew/issues/#issue/41
  # http://github.com/mxcl/homebrew/issues/#issue/48

  %w[port fink].each do |ponk|
    path = `/usr/bin/which -s #{ponk}`
    return ponk unless path.empty?
  end

  # we do the above check because macports can be relocated and fink may be
  # able to be relocated in the future. This following check is because if
  # fink and macports are not in the PATH but are still installed it can
  # *still* break the build -- because some build scripts hardcode these paths:
  %w[/sw/bin/fink /opt/local/bin/port].each do |ponk|
    return ponk if File.exist? ponk
  end

  # finally, sometimes people make their MacPorts or Fink read-only so they
  # can quickly test Homebrew out, but still in theory obey the README's 
  # advise to rename the root directory. This doesn't work, many build scripts
  # error out when they try to read from these now unreadable directories.
  %w[/sw /opt/local].each do |path|
    path = Pathname.new(path)
    return path if path.exist? and not path.readable?
  end
  
  false
end

def outdated_brews
  require 'formula'

  results = []
  HOMEBREW_CELLAR.subdirs.each do |keg|
    # Skip kegs with no versions installed
    next unless keg.subdirs

    # Skip HEAD formulae, consider them "evergreen"
    next if keg.subdirs.collect{|p|p.basename.to_s}.include? "HEAD"

    name = keg.basename.to_s
    if (not (f = Formula.factory(name)).installed? rescue nil)
      results << [keg, name, f.version]
    end
  end
  return results
end

def search_brews text
  require "formula"

  return Formula.names if text.to_s.empty?

  rx = if text =~ %r{^/(.*)/$}
    Regexp.new($1)
  else
    /.*#{Regexp.escape text}.*/i
  end

  aliases = Formula.aliases
  results = (Formula.names+aliases).grep rx

  # Filter out aliases when the full name was also found
  results.reject do |alias_name|
    if aliases.include? alias_name
      results.include? Formula.resolve_alias(alias_name)
    end
  end
end

def brew_install
  require 'formula_installer'
  require 'hardware'

  ############################################################ sanity checks
  case Hardware.cpu_type when :ppc, :dunno
    abort "Sorry, Homebrew does not support your computer's CPU architecture.\n"+
          "For PPC support, see: http://github.com/sceaga/homebrew/tree/powerpc"
  end

  raise "Cannot write to #{HOMEBREW_CELLAR}" if HOMEBREW_CELLAR.exist? and not HOMEBREW_CELLAR.writable?
  raise "Cannot write to #{HOMEBREW_PREFIX}" unless HOMEBREW_PREFIX.writable?

  ################################################################# warnings
  begin
    if MACOS_VERSION >= 10.6
      opoo "You should upgrade to Xcode 3.2.3" if llvm_build < RECOMMENDED_LLVM
    else
      opoo "You should upgrade to Xcode 3.1.4" if (gcc_40_build < RECOMMENDED_GCC_40) or (gcc_42_build < RECOMMENDED_GCC_42)
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

  ################################################################# install!
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

def gcc_42_build
  `/usr/bin/gcc-4.2 -v 2>&1` =~ /build (\d{4,})/
  if $1
    $1.to_i 
  elsif system "/usr/bin/which gcc"
    # Xcode 3.0 didn't come with gcc-4.2
    # We can't change the above regex to use gcc because the version numbers
    # are different and thus, not useful.
    # FIXME I bet you 20 quid this causes a side effect — magic values tend to
    401
  else
    nil
  end
end
alias :gcc_build :gcc_42_build # For compatibility

def gcc_40_build
  `/usr/bin/gcc-4.0 -v 2>&1` =~ /build (\d{4,})/
  if $1
    $1.to_i 
  else
    nil
  end
end

def llvm_build
  if MACOS_VERSION >= 10.6
    xcode_path = `/usr/bin/xcode-select -print-path`.chomp
    return nil if xcode_path.empty?
    `#{xcode_path}/usr/bin/llvm-gcc -v 2>&1` =~ /LLVM build (\d{4,})/
    $1.to_i
  end
end

def xcode_version
  `xcodebuild -version 2>&1` =~ /Xcode (\d(\.\d)*)/
  return $1 ? $1 : nil
end

def _compiler_recommendation build, recommended
  message = (!build.nil? && build < recommended) ? "(#{recommended} or newer recommended)" : ""
  return build, message
end

def dump_config
  require 'hardware'
  sha = `cd #{HOMEBREW_REPOSITORY} && git rev-parse --verify HEAD 2> /dev/null`.chomp
  sha = "(none)" if sha.empty?
  bits = Hardware.bits
  cores = Hardware.cores_as_words
  kernel_arch = `uname -m`.chomp
  system_ruby = Pathname.new("/usr/bin/ruby")

  llvm,   llvm_msg   = _compiler_recommendation llvm_build,   RECOMMENDED_LLVM
  gcc_42, gcc_42_msg = _compiler_recommendation gcc_42_build, RECOMMENDED_GCC_42
  gcc_40, gcc_40_msg = _compiler_recommendation gcc_40_build, RECOMMENDED_GCC_40
  xcode = xcode_version || "?"

  puts <<-EOS
HOMEBREW_VERSION: #{HOMEBREW_VERSION}
HEAD: #{sha}
HOMEBREW_PREFIX: #{HOMEBREW_PREFIX}
HOMEBREW_CELLAR: #{HOMEBREW_CELLAR}
HOMEBREW_REPOSITORY: #{HOMEBREW_REPOSITORY}
HOMEBREW_LIBRARY_PATH: #{HOMEBREW_LIBRARY_PATH}
Hardware: #{cores}-core #{bits}-bit #{Hardware.intel_family}
OS X: #{MACOS_FULL_VERSION}
Kernel Architecture: #{kernel_arch}
Ruby: #{RUBY_VERSION}-#{RUBY_PATCHLEVEL}
/usr/bin/ruby => #{system_ruby.realpath}
Xcode: #{xcode}
GCC-4.0: #{gcc_40 ? "build #{gcc_40}" : "N/A"} #{gcc_42_msg}
GCC-4.2: #{gcc_42 ? "build #{gcc_42}" : "N/A"} #{gcc_40_msg}
LLVM: #{llvm ? "build #{llvm}" : "N/A" } #{llvm_msg}
MacPorts or Fink? #{macports_or_fink_installed?}
X11 installed? #{x11_installed?}
EOS
end
