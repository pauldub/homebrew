def brew_deps
  if ARGV.include?('--all')
    require 'formula'
    Formula.all.each do |f|
      puts "#{f.name}:#{f.deps.join(' ')}"
    end
  elsif ARGV.include?("-1") or ARGV.include?("--1")
    puts *ARGV.formulae.map{ |f| f.deps or [] }.flatten.uniq.sort
  else
    require 'formula_installer'
    puts ARGV.formulae.map{ |f| FormulaInstaller.expand_deps(f).map{|f| f.name} }.flatten.uniq.sort
  end
end