def brew_outdated
  outdated_brews.each do |keg, name, version|
    if $stdout.tty? and not ARGV.flag? '--quiet'
      versions = keg.cd{ Dir['*'] }.join(', ')
      puts "#{name} (#{versions} < #{version})"
    else
      puts name
    end
  end
end