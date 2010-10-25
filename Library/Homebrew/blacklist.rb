def check_for_blacklisted_formula names
  return if ARGV.force?

  names.each do |name|
    case name
    when 'tex', 'tex-live', 'texlive' then abort <<-EOS.undent
      Installing TeX from source is weird and gross, requires a lot of patches,
      and only builds 32-bit (and thus can't use Homebrew deps on Snow Leopard.)

      We recommend using a MacTeX distribution:
        http://www.tug.org/mactex/
    EOS

    when 'mercurial', 'hg' then abort <<-EOS.undent
      Mercurial can be install thusly:
        brew install pip && pip install mercurial
    EOS

    when 'setuptools' then abort <<-EOS.undent
      When working with a Homebrew-built Python, distribute is preferred
      over setuptools, and can be used as the pre-requisite for pip.

      Install distribute using:
        brew install distribute
    EOS
    end
  end
end

def check_for_blacklisted_formula_create name
  return if ARGV.force?

  force_text = "If you really want to make this formula use --force."

  case name.downcase
  when 'vim', 'screen'
    raise <<-EOS
#{name} is blacklisted for creation
Apple distributes this program with OS X.

#{force_text}
    EOS
  when 'libarchive', 'libpcap'
    raise <<-EOS
#{name} is blacklisted for creation
Apple distributes this library with OS X, you can find it in /usr/lib.

#{force_text}
    EOS
  when 'libxml', 'libxlst', 'freetype', 'libpng'
    raise <<-EOS
#{name} is blacklisted for creation
Apple distributes this library with OS X, you can find it in /usr/X11/lib.
However not all build scripts look here, so you may need to call ENV.x11 or
ENV.libxml2 in your formula's install function.

#{force_text}
    EOS
  when 'rubygem'
    raise "Sorry RubyGems comes with OS X so we don't package it.\n\n#{force_text}"
  when 'wxwidgets'
    raise <<-EOS
#{name} is blacklisted for creation
An older version of wxWidgets is provided by Apple with OS X, but
a formula for wxWidgets 2.8.10 is provided:

    brew install wxmac

  #{force_text}
    EOS
  end
end