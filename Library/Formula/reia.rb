require 'formula'

class Reia < Formula
  version 'HEAD' #Reia only has Git-repository, no stable versions released and
                 #Reia cannot be installed into a directory with dots in it like 0.1 (at this time)
  url 'git://github.com/tarcieri/reia.git'
  homepage 'http://reia-lang.org/'
  md5 '' #Git-repository only, no stable version and no MD5 available

  depends_on 'erlang'

  def install
    system 'rake'                                           #build and test Reia
    %w(bin/ire bin/reia).each do |f|                        #Change some paths in scripts
      inreplace f, /^(EXTRA_PATHS=).*$/, "\\1\"-pz #{prefix}/ebin\""
      inreplace f, /^(export REIA_HOME=)\.$/, "\\1#{prefix}"
    end
    libexec.install Dir['lib']                              #move contents of lib to libexec
    prefix.install Dir['*']                                 #install the rest
    lib.mkpath                                              #create lib-folder
    Dir["#{libexec}/lib/*"].each { |f| ln_s f, lib }        #link contents of libexec/lib to lib
  end
end