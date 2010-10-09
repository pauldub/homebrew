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
