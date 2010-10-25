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
end
