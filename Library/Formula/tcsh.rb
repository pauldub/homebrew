require 'formula'

class Tcsh <Formula
  url 'ftp://ftp.astron.com/pub/tcsh/tcsh-6.18.01.tar.gz'
  homepage 'http://www.tcsh.org/'
  md5 '6eed09dbd4223ab5b6955378450d228a'
  version '6.18.01'

  # depends_on 'cmake'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    # system "cmake . #{std_cmake_parameters}"
    system "make install"
  end
end
