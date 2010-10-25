require 'formula'

def cleanup name
  f = Formula.factory name
  formula_cellar = f.prefix.parent

  if f.installed? and formula_cellar.directory?
    kids = f.prefix.parent.children
    kids.each do |keg|
      next if f.installed_prefix == keg
      print "Uninstalling #{keg}..."
      FileUtils.rm_rf keg
      puts
    end
  else
    # If the cellar only has one version installed, don't complain
    # that we can't tell which one to keep.
    if formula_cellar.children.length > 1
      opoo "Skipping #{name}: most recent version #{f.version} not installed"
    end
  end
end

def brew_cleanup
  if ARGV.named.empty?
    HOMEBREW_CELLAR.racks.each do |rack|
      begin
        cleanup(rack.basename.to_s)
      rescue FormulaUnavailableError => e
        opoo "Formula not found for #{e.name}"
      end
    end
    prune # seems like a good time to do some additional cleanup
  else
    ARGV.named.each { |name| cleanup name}
  end
end
