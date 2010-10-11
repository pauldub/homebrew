# For each formula given, show which other formulas depend on it.
# We only go one level up, ie. direct dependencies.

def brew_uses
  uses = ARGV.formulae.map{ |f| Formula.all.select{ |ff| ff.deps.include? f.name }.map{|f| f.name} }.flatten.uniq
  if ARGV.include? "--installed"
    uses = uses.select { |f| f = HOMEBREW_CELLAR+f; f.directory? and not f.subdirs.empty? }
  end
  puts uses.sort
end