class Cellar <Pathname
  def initialize path
    super path
  end

  def outdated_brews
    require 'formula'

    results = []
    self.subdirs.each do |keg|
      # Skip kegs with no versions installed
      next unless keg.subdirs

      # Skip HEAD formulae, consider them "evergreen"
      next if keg.subdirs.collect{|p|p.basename.to_s}.include? "HEAD"

      name = keg.basename.to_s
      if (not (f = Formula.factory(name)).installed? rescue nil)
        results << [keg, name, f.version]
      end
    end
    return results
  end
end
