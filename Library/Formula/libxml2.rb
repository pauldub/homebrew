require 'formula'

def build_python?; ARGV.include? "--python"; end

class Libxml2 <Formula
  url 'ftp://xmlsoft.org/libxml2/libxml2-2.7.7.tar.gz'
  homepage 'http://xmlsoft.org'
  md5 '9abc9959823ca9ff904f1fbcf21df066'

  keg_only :provided_by_osx

  def options
    [["--python", "Also build and install Python bindings."]]
  end

  def install
    fails_with_llvm "Undefined symbols when linking", :build => "2326"

    args = ["--disable-dependency-tracking", "--prefix=#{prefix}"]

    if build_python?
      args << "--with-python=`python-config --prefix`"
    end

    system "./configure", *args
    system "make"
    ENV.j1
    system "make install"
  end
end
