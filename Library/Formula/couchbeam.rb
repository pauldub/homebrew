require 'formula'

class Couchbeam <Formula
  homepage 'http://benoitc.github.com/couchbeam/'

  url 'http://github.com/benoitc/couchbeam/tarball/0.4.2'
  md5 '72dbc30a1ad9a1dd2de22d2f36d910a6'

  depends_on 'erlang'

  def install
    erlang = Formulary.read("erlang").new("erlang")
    system "make"
    system "cp -R . #{prefix}"
    system "ln -s #{prefix} #{erlang.lib}/erlang/lib/couchbeam-#{version}"
  end
end
