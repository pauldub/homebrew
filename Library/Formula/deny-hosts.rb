require 'formula'

class DenyHosts <Formula
  url 'http://downloads.sourceforge.net/project/denyhosts/denyhosts/2.6/DenyHosts-2.6.tar.gz'
  homepage 'http://denyhosts.sourceforge.net/'
  md5 'fc2365305a9402886a2b0173d1beb7df'

  def install
    my_share = share+'denyhosts'

    inreplace "daemon-control-dist" do |s|
      s.change_make_var! "DENYHOSTS_BIN", libexec+"denyhosts.py"
      s.change_make_var! "DENYHOSTS_CFG", my_share+"denyhosts.cfg"
    end

    # See: http://trac.macports.org/browser/trunk/dports/security/denyhosts/files/patch-denyhosts.cfg-dist.diff

    my_share.install Dir["*-dist"]
    my_share.install "scripts"
    my_share.install "plugins"

    libexec.mkpath
    libexec.install "denyhosts.py"
    libexec.install "DenyHosts"

    bin.mkpath
    (bin+'denyhosts').write <<-EOS.undent
      #!/bin/bash
      python #{libexec}/denyhosts.py
    EOS
  end

  def caveats; <<-EOS
    Sample configuration written to:
      #{my_share}/denyhosts.cfg-dist

    You'll need to copy this to:
      #{my_share}/denyhosts.cfg
    and configure for your system.
    EOS
  end
end
