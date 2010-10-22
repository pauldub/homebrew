require 'formula'

class Couchbeam <Formula
  homepage 'http://benoitc.github.com/couchbeam/'
  url 'http://github.com/benoitc/couchbeam/tarball/0.5.1'
  md5 'a11ce498d42f348fdeef90d0286de4aa'

  depends_on 'erlang'

  def install
    ENV.j1 # Can't get multiple deps at once
    erlang_lib = Formula.factory("erlang").lib
    system "make"
    libexec.install Dir['*']
    system "ln -s #{libexec} #{erlang_lib}/erlang/lib/couchbeam-#{version}"
  end
end
