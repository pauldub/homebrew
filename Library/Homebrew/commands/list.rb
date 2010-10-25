class PrettyListing
  def initialize path
    Pathname.new(path).children.sort{ |a,b| a.to_s.downcase <=> b.to_s.downcase }.each do |pn|
      case pn.basename.to_s
      when 'bin', 'sbin'
        pn.find { |pnn| puts pnn unless pnn.directory? or pnn.basename.to_s == '.DS_Store' }
      when 'lib'
        print_dir pn do |pnn|
          # dylibs have multiple symlinks and we don't care about them
          (pnn.extname == '.dylib' or pnn.extname == '.pc') and not pnn.symlink?
        end
      else
        if pn.directory?
          if pn.symlink?
            puts "#{pn} -> #{pn.readlink}"
          else
            print_dir pn
          end
        elsif not (FORMULA_META_FILES.include? pn.basename.to_s or pn.basename.to_s == '.DS_Store')
          puts pn
        end
      end
    end
  end

private
  def print_dir root
    dirs = []
    remaining_root_files = []
    other = ''

    root.children.sort.each do |pn|
      if pn.directory?
        dirs << pn
      elsif block_given? and yield pn
        puts pn
        other = 'other '
      else
        remaining_root_files << pn unless pn.basename.to_s == '.DS_Store'
      end
    end

    dirs.each do |d|
      files = []
      d.find { |pn| files << pn unless pn.directory? }
      print_remaining_files files, d
    end

    print_remaining_files remaining_root_files, root, other
  end

  def print_remaining_files files, root, other = ''
    case files.length
    when 0
      # noop
    when 1
      puts files
    else
      puts "#{root}/ (#{files.length} #{other}files)"
    end
  end
end

def brew_list_unbrewed
  dirs = HOMEBREW_PREFIX.unbrewed_dirs
  Dir.chdir HOMEBREW_PREFIX
  exec 'find', *dirs + %w[-type f ( ! -iname .ds_store ! -iname brew )]
end

def brew_list_versions
  if ARGV.named.empty?
    to_list = HOMEBREW_CELLAR.racks
  else
    to_list = ARGV.named.collect { |n| HOMEBREW_CELLAR+n }.select { |pn| pn.exist? }
  end
  to_list.each do |d|
    versions = d.children.select { |pn| pn.directory? }.collect { |pn| pn.basename.to_s }
    puts "#{d.basename} #{versions *' '}"
  end
end

def brew_list
  if ARGV.flag? '--unbrewed'
    brew_list_unbrewed
  elsif ARGV.flag? '--versions'
    brew_list_versions
  elsif ARGV.named.empty?
    ENV['CLICOLOR']=nil
    exec 'ls', *ARGV.options_only<<HOMEBREW_CELLAR if HOMEBREW_CELLAR.exist?
  elsif ARGV.verbose? or not $stdout.tty?
    exec "find", *ARGV.kegs+%w[-not -type d -print]
  else
    ARGV.kegs.each { |keg| PrettyListing.new keg }
  end
end