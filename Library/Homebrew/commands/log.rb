def brew_log
  Dir.chdir HOMEBREW_REPOSITORY
  args = ARGV.options_only
  args += ARGV.formulae.map{ |f| f.path } unless ARGV.named.empty?
  exec "git", "log", *args
end