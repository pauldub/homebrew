def brew_cat
  Dir.chdir HOMEBREW_REPOSITORY
  exec "cat", ARGV.formulae.first.path, *ARGV.options_only
end