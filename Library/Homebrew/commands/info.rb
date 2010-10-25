require 'formula'

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
      print " *" if f.prefix == keg and kids.length > 1
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

def brew_info
  if ARGV.named.empty?
    if ARGV.include? "--all"
      Formula.all.each do |f|
        info f
        puts '---'
      end
    else
      puts `ls #{HOMEBREW_CELLAR} | wc -l`.strip+" kegs, "+HOMEBREW_CELLAR.abv
    end
  elsif ARGV[0][0..6] == 'http://' or ARGV[0][0..7] == 'https://' or ARGV[0][0..5] == 'ftp://'
    path = Pathname.new(ARGV.shift)
    /(.*?)[-_.]?#{path.version}/.match path.basename
    unless $1.to_s.empty?
      name = $1
    else
      name = path.stem
    end
    puts "#{name} #{path.version}"
  else
    ARGV.formulae.each{ |f| info f }
  end
end