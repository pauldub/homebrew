require 'formula'

class Mono <Formula
  url "http://ftp.novell.com/pub/mono/sources/mono/mono-2.8.tar.bz2"
  homepage "http://mono-project.com/"
  md5 "30b1180e20e5110d3fb36147137014a0"

  depends_on "pkg-config"

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--with-glib=embedded",
                          "--enable-nls=no"
    system "make"
    system "make install"
  end
end