require 'formula'

# Required for head builds
class Autoconf268 <Formula
  url 'http://ftp.gnu.org/gnu/autoconf/autoconf-2.68.tar.bz2'
  md5 '864d785215aa60d627c91fcb21b05b07'
  homepage 'http://www.gnu.org/software/autoconf/'
end

class GnuLibtool24 <Formula
  url "http://ftp.gnu.org/gnu/libtool/libtool-2.4.tar.gz"
end

# References:
# * http://smalltalk.gnu.org/wiki/building-gst-guides
#
# Note that we build 32-bit, which means that 64-bit
# optional dependencies will break the build. You may need
# to "brew unlink" these before installing GNU Smalltalk and
# "brew link" them afterwards:
# * gdbm

class GnuSmalltalk <Formula
  url 'ftp://ftp.gnu.org/gnu/smalltalk/smalltalk-3.2.2.tar.gz'
  homepage 'http://smalltalk.gnu.org/'
  sha1 'a985d69e4760420614c9dfe4d3605e47c5eb8faa'

  head "git://git.sv.gnu.org/smalltalk.git"

  # 'gmp' is an optional dep, it is built 64-bit on Snow Leopard
  # (and this brew is forced to build in 32-bit mode.)

   if ARGV.build_head?
    depends_on 'gdbm'
    depends_on 'gmp'
  end

  def install
    fails_with_llvm "Codegen problems with LLVM"

    unless ARGV.build_head?
      # 64-bit version doesn't build, so force 32 bits.
      ENV.m32

      if snow_leopard_64? and Formula.factory('gdbm').installed?
        onoe "A 64-bit gdbm will cause linker errors"
        puts <<-EOS.undent
          GNU Smalltak doesn't compile 64-bit clean on OS X, so having a
          64-bit gdbm installed will break linking you may want to do:
            $ brew unlink gdbm
            $ brew install gnu-smalltalk
            $ brew link gdbm
        EOS
      end
    end

    # GNU Smalltalk thinks it needs GNU awk, but it works fine
    # with OS X awk, so let's trick configure.
    here = Dir.pwd
    system "ln -s /usr/bin/awk #{here}/gawk"
    ENV['AWK'] = "#{here}/gawk"

    # Head builds require newer Autoconf than comes with OS X
    if ARGV.build_head?
      autoconf_prefix = Pathname.pwd.join('custom_autoconf')
      Autoconf268.new.brew do |f|
        system "./configure", "--program-suffix=_custom",
                              "--prefix=#{autoconf_prefix}"
        system "make install"
      end

      system "#{autoconf_prefix}/bin/autoreconf_custom", "-fvi"
    end

    ENV['FFI_CFLAGS'] = '-I/usr/include/ffi'
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-readline=/usr/lib"
    system "make"
    ENV.j1 # Parallel install doesn't work
    system "make install"
  end
end
