class HomebrewPrefix <Pathname
  def initialize path
    super path
  end

  def prune
    dirs=Array.new
    paths=%w[bin sbin etc lib include share].collect {|d| self+d}

    paths.each do |path|
      path.find do |p|
        p.extend ObserverPathnameExtension
        if p.symlink?
          p.unlink unless p.resolved_path_exists?
        elsif p.directory?
          dirs << p
        end
      end
    end

    dirs.sort.reverse_each {|d| d.rmdir_if_possible}
  end

  def unbrewed_dirs
    dirs = self.children.select { |pn| pn.directory? }.collect { |pn| pn.basename.to_s }
    dirs -= ['Library', 'Cellar', '.git']
    return dirs
  end
end


class Cellar <Pathname
  def initialize path
    super path
  end

  def racks
    self.children.select { |pn| pn.directory? }
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
