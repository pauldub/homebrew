def brew_prune
  $n=0
  $d=0

  dirs=Array.new
  paths=%w[bin sbin etc lib include share].collect {|d| HOMEBREW_PREFIX+d}

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

  if $n == 0 and $d == 0
    puts "Nothing pruned" if ARGV.verbose?
  else
    # always showing symlinks text is deliberate
    print "Pruned #{$n} symbolic links "
    print "and #{$d} directories " if $d > 0
    puts  "from #{HOMEBREW_PREFIX}"
  end
end