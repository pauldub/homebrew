require 'formula'

class Reia < Formula
  head 'git://github.com/tarcieri/reia.git'
  homepage 'http://reia-lang.org/'

  depends_on 'erlang'

  def install
    system 'rake'

    # Change some paths in scripts
    %w(bin/ire bin/reia).each do |f|
      inreplace f, /^(EXTRA_PATHS=).*$/, "\\1\"-pz #{prefix}/ebin\""
      inreplace f, /^(export REIA_HOME=)\.$/, "\\1#{prefix}"
    end

    # move contents of lib to libexec
    libexec.install 'lib'
    # install the rest
    prefix.install Dir['*']

    # link contents of libexec/lib to lib
    lib.mkpath
    Dir["#{libexec}/lib/*"].each { |f| ln_s f, lib }
  end
end