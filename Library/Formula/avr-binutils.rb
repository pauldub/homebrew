require 'formula'

class AvrBinutils <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.20.tar.gz'
  homepage 'http://www.gnu.org/software/binutils/binutils.html'
  md5 'e99487e0c4343d6fa68b7c464ff4a962'

  def install
    ENV.append 'CPPFLAGS', "-I#{include}"

    args = ["--prefix=#{prefix}",
            "--disable-debug",
            "--disable-dependency-tracking",
            "--infodir=#{info}",
            "--mandir=#{man}",
            "--disable-werror",
	    "--target=avr" ]

    system "./configure", *args
    system "make"
    system "make install"
  end
end
