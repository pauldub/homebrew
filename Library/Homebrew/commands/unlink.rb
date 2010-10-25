def brew_unlink
  ARGV.kegs.each {|keg| puts "#{keg.unlink} links removed for #{keg}"}
end