def brew_search
  if ARGV.include? '--macports'
    exec "open", "http://www.macports.org/ports.php?by=name&substr=#{ARGV.next}"
  elsif ARGV.include? '--fink'
    exec "open", "http://pdb.finkproject.org/pdb/browse.php?summary=#{ARGV.next}"
  end

  check_for_blacklisted_formula(ARGV.named)
  puts_columns search_brews(ARGV.first)
end