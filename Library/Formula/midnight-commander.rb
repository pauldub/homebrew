require 'formula'

class MidnightCommander <Formula
  url 'http://www.midnight-commander.org/downloads/mc-4.7.0.9.tar.bz2'
  homepage 'http://www.midnight-commander.org/'
  sha256 '52f5b8e2fdbbc24fe487909d36f36622c351061b4e10bbcd3812b0c2b6bac385'

  depends_on 'pkg-config' => :build
  depends_on 'glib'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--without-x",
                          "--with-screen=ncurses"
    system "make install"
  end
end
