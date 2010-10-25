require 'digest'
require 'erb'
require 'blacklist'
require 'formula'

def __make url, name
  path = Formula.path(name)
  raise "#{path} already exists" if path.exist?

  if Formula.aliases.include? name and not ARGV.force?
    realname = Formula.resolve_alias(name)
    raise <<-EOS.undent
          "#{name}" is an alias for formula "#{realname}".
          Please check that you are not creating a duplicate.
          To force creation use --force.
          EOS
  end

  if ARGV.include? '--cmake'
    mode = :cmake
  elsif ARGV.include? '--autotools'
    mode = :autotools
  else
    mode = nil
  end

  version = Pathname.new(url).version
  if version.nil?
    opoo "Version cannot be determined from URL."
    puts "You'll need to add an explicit 'version' to the formula."
  else
    puts "Version detected as #{version}."
  end

  md5 = ''
  if ARGV.include? "--cache" and version != nil
    strategy = detect_download_strategy url
    if strategy == CurlDownloadStrategy
      d = strategy.new url, name, version, nil
      the_tarball = d.fetch
      md5 = the_tarball.md5
      puts "MD5 is #{md5}"
    else
      puts "--cache requested, but we can only cache formulas that use Curl."
    end
  end

  formula_template = <<-EOS
require 'formula'

class #{Formula.class_s name} <Formula
  url '#{url}'
  homepage ''
  md5 '#{md5}'

<% if mode == :cmake %>
  depends_on 'cmake'
<% elsif mode == nil %>
  # depends_on 'cmake'
<% end %>

  def install
<% if mode == :cmake %>
    system "cmake . \#{std_cmake_parameters}"
<% elsif mode == :autotools %>
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=\#{prefix}"
<% else %>
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=\#{prefix}"
    # system "cmake . \#{std_cmake_parameters}"
<% end %>
    system "make install"
  end
end
  EOS

  path.write(ERB.new(formula_template, nil, '>').result(binding))
  return path
end

def make url
  path = Pathname.new url

  /(.*?)[-_.]?#{path.version}/.match path.basename

  unless $1.to_s.empty?
    name = $1
  else
    print "Formula name [#{path.stem}]: "
    gots = $stdin.gets.chomp
    if gots.empty?
      name = path.stem
    else
      name = gots
    end
  end

  check_for_blacklisted_formula_create name
  __make url, name
end

def brew_create
  raise UsageError if ARGV.named.empty?

  if ARGV.include? '--macports'
    exec "open", "http://www.macports.org/ports.php?by=name&substr=#{ARGV.next}"
  elsif ARGV.include? '--fink'
    exec "open", "http://pdb.finkproject.org/pdb/browse.php?summary=#{ARGV.next}"
  else
    exec_editor(*ARGV.named.collect {|name| make name})
  end
end