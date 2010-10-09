def brew_home
  if ARGV.named.empty?
    exec "open", HOMEBREW_WWW
  else
    exec "open", *ARGV.formulae.collect {|f| f.homepage}
  end
end