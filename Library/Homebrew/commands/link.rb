def brew_link
  ARGV.kegs.each {|keg| puts "#{keg.link} links created for #{keg}"}
end