def brew_remove
  if ARGV.flag? "--force"
    require 'formula'
    ARGV.formulae.each do |f|
      formula_cellar = f.prefix.parent
      next unless File.exist? formula_cellar
      puts "Uninstalling #{f.name}..."
      formula_cellar.children do |k|
        keg = Keg.new(k)
        keg.unlink
      end

      formula_cellar.rmtree
    end
  else
    begin
      ARGV.kegs.each do |keg|
        puts "Uninstalling #{keg}..."
        keg.unlink
        keg.uninstall
      end
    rescue MultipleVersionsInstalledError => e
      onoe e
      puts "Use `brew remove --force #{e.name}` to remove all versions."
    end
  end
end