require 'formula'

# See:
# * http://www.virtualbox.org/wiki/Mac%20OS%20X%20build%20instructions
# * http://forums.virtualbox.org/viewtopic.php?f=10&t=28561

class Virtualbox <Formula
  url 'http://download.virtualbox.org/virtualbox/3.2.6/VirtualBox-3.2.6-OSE.tar.bz2'
  version '3.2.6-OSE'
  homepage 'http://www.virtualbox.org/'
  md5 '65b822ab3c08ff882d9621101996dc14'

  depends_on "libidl"
  depends_on "openssl" # System-provided version is too old.
  depends_on "qt"

  # def patches
  #   DATA if MACOS_VERSION >= 10.6 and Hardware.is_64_bit?
  # end

  def install
    openssl_prefix = Formula.factory("openssl").prefix

    args = ["--disable-hardening",
            "--with-openssl-dir=#{openssl_prefix}",
            "--with-qt-dir=#{HOMEBREW_PREFIX}"]

    args << "--target-arch=amd64" if MACOS_VERSION >= 10.6 and Hardware.is_64_bit?

    system "./configure", *args
    system ". ./env.sh ; kmk"

    # Move all the build outputs into libexec
    libexec.install Dir["out/darwin.*/release/dist/*"]

    app_contents = libexec+"VirtualBox.app/Contents/MacOS/"

    # remove test scripts and files
    (app_contents+"testcase").rmtree
    FileUtils.rm Dir.glob(app_contents+"tst*")


    # Slot the command-line tools into bin
    bin.mkpath

    cd prefix do
      %w[ VBoxHeadless VBoxManage VBoxVRDP vboxwebsrv ].each do |c|
        ln_s "libexec/VirtualBox.app/Contents/MacOS/#{c}", "bin" if File.exist? app_contents+c
      end
    end
  end

  def caveats
    <<-EOS.undent
      Compiled outputs installed to:
        #{libexec}
      You'll need to figure out what to do about the kernel extensions.

      Pre-compiled binaries are available from:
        http://www.virtualbox.org/wiki/Downloads
    EOS
  end
end


__END__
--- VirtualBox-3.2.0_OSE-orig/configure   2010-05-05 04:15:09.000000000 -0700
+++ VirtualBox-3.2.0_OSE/configure   2010-05-23 20:43:35.000000000 -0700
@@ -1986,11 +1986,9 @@
   case "$darwin_ver" in
     10\.*)
       darwin_ver="10.6"
-      sdk=/Developer/SDKs/MacOSX10.5.sdk
-      CXX_FLAGS="-mmacosx-version-min=10.5 -isysroot $sdk -Wl,-syslibroot,$sdk"
-#      test "$CC" = "gcc" && CC="gcc-4.0"
-#      test "$CXX" = "g++" && CXX="g++-4.0"
-      cnf_append "VBOX_MACOS_10_5_WORKAROUND" "1"
+      sdk=/Developer/SDKs/MacOSX10.6.sdk
+      CXX_FLAGS="-mmacosx-version-min=10.6 -isysroot $sdk -Wl,-syslibroot,$sdk"
+      cnf_append "VBOX_MACOS_10_6_WORKAROUND" "1"
       ;;
     9\.*)
       darwin_ver="10.5"


--- VirtualBox-3.2.0_OSE-orig/Config.kmk   2010-05-18 11:10:48.000000000 -0700
+++ VirtualBox-3.2.0_OSE/Config.kmk   2010-05-23 19:46:49.000000000 -0700
@@ -2534,6 +2534,14 @@
 TEMPLATE_VBOXR0DRVOSX105_CFLAGS        = $(subst $(VBOX_DARWIN_DEF_SDK_CFLAGS),$(VBOX_DARWIN_DEF_SDK_10_5_CFLAGS),$(TEMPLATE_VBOXR0DRV_CFLAGS))
 TEMPLATE_VBOXR0DRVOSX105_CXXFLAGS      = $(subst $(VBOX_DARWIN_DEF_SDK_CXXFLAGS),$(VBOX_DARWIN_DEF_SDK_10_5_CXXFLAGS),$(TEMPLATE_VBOXR0DRV_CXXFLAGS))
 TEMPLATE_VBOXR0DRVOSX105_LDFLAGS       = $(subst $(VBOX_DARWIN_DEF_SDK_LDFLAGS),$(VBOX_DARWIN_DEF_SDK_10_5_LDFLAGS),$(TEMPLATE_VBOXR0DRV_LDFLAGS))
+
+TEMPLATE_VBOXR0DRVOSX106               = Mac OS X 10.6 variant.
+TEMPLATE_VBOXR0DRVOSX106_EXTENDS       = VBOXR0DRV
+TEMPLATE_VBOXR0DRVOSX106_DEFS          = $(subst $(VBOX_DARWIN_DEF_SDK_DEFS),$(VBOX_DARWIN_DEF_SDK_10_6_DEFS),$(TEMPLATE_VBOXR0DRV_DEFS))
+TEMPLATE_VBOXR0DRVOSX106_INCS          = $(subst $(VBOX_PATH_MACOSX_SDK),$(VBOX_PATH_MACOSX_SDK_10_6),$(TEMPLATE_VBOXR0DRV_INCS))
+TEMPLATE_VBOXR0DRVOSX106_CFLAGS        = $(subst $(VBOX_DARWIN_DEF_SDK_CFLAGS),$(VBOX_DARWIN_DEF_SDK_10_6_CFLAGS),$(TEMPLATE_VBOXR0DRV_CFLAGS))
+TEMPLATE_VBOXR0DRVOSX106_CXXFLAGS      = $(subst $(VBOX_DARWIN_DEF_SDK_CXXFLAGS),$(VBOX_DARWIN_DEF_SDK_10_6_CXXFLAGS),$(TEMPLATE_VBOXR0DRV_CXXFLAGS))
+TEMPLATE_VBOXR0DRVOSX106_LDFLAGS       = $(subst $(VBOX_DARWIN_DEF_SDK_LDFLAGS),$(VBOX_DARWIN_DEF_SDK_10_6_LDFLAGS),$(TEMPLATE_VBOXR0DRV_LDFLAGS))
 endif
 
 ifeq ($(KBUILD_TARGET),solaris)
@@ -2957,6 +2965,21 @@
   -current_version $(VBOX_VERSION_MAJOR).$(VBOX_VERSION_MINOR).$(VBOX_VERSION_BUILD) \
   -compatibility_version $(VBOX_VERSION_MAJOR).$(VBOX_VERSION_MINOR).$(VBOX_VERSION_BUILD)
 
+#
+# Template for building R3 shared objects / DLLs with the 10.6 Mac OS X SDK.
+# Identical to VBOXR3EXE, except for the DYLIB, the classic_linker and SDK bits.
+#
+TEMPLATE_VBOXR3OSX106  = VBox Ring 3 SO/DLLs for OS X 10.6
+TEMPLATE_VBOXR3OSX106_EXTENDS = VBOXR3EXE
+TEMPLATE_VBOXR3OSX106_DEFS.darwin        = $(VBOX_DARWIN_DEF_SDK_10_6_DEFS) PIC
+TEMPLATE_VBOXR3OSX106_CFLAGS.darwin      = $(VBOX_DARWIN_DEF_SDK_10_6_CFLAGS) -fno-common
+TEMPLATE_VBOXR3OSX106_CXXFLAGS.darwin    = $(VBOX_DARWIN_DEF_SDK_10_6_CXXFLAGS)
+TEMPLATE_VBOXR3OSX106_OBJCFLAGS.darwin   = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCFLAGS)
+TEMPLATE_VBOXR3OSX106_OBJCXXFLAGS.darwin = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCFLAGS)
+TEMPLATE_VBOXR3OSX106_LDFLAGS.darwin     = $(VBOX_DARWIN_DEF_SDK_10_6_LDFLAGS) \
+   -read_only_relocs suppress \
+   -current_version $(VBOX_VERSION_MAJOR).$(VBOX_VERSION_MINOR).$(VBOX_VERSION_BUILD) \
+   -compatibility_version $(VBOX_VERSION_MAJOR).$(VBOX_VERSION_MINOR).$(VBOX_VERSION_BUILD)
 
 #
 # Ring-3 testcase, running automatically during the build.
@@ -3716,6 +3739,13 @@
 TEMPLATE_VBOXBLDPROG_OBJCFLAGS.darwin    = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCFLAGS) $(VBOX_GCC_PEDANTIC_C)
 TEMPLATE_VBOXBLDPROG_OBJCXXFLAGS.darwin  = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCXXFLAGS) $(VBOX_GCC_PEDANTIC_CXX)
 TEMPLATE_VBOXBLDPROG_LDFLAGS.darwin      = $(VBOX_DARWIN_DEF_SDK_10_6_LDFLAGS)
+  else ifdef VBOX_MACOS_10_6_WORKAROUND # enable this if you have problems linking xpidl and is running 10.6 or later.
+TEMPLATE_VBOXBLDPROG_DEFS.darwin         = $(VBOX_DARWIN_DEF_SDK_10_6_DEFS)
+TEMPLATE_VBOXBLDPROG_CFLAGS.darwin       = $(VBOX_DARWIN_DEF_SDK_10_6_CFLAGS) -fno-common
+TEMPLATE_VBOXBLDPROG_CXXFLAGS.darwin     = $(VBOX_DARWIN_DEF_SDK_10_6_CXXFLAGS)
+TEMPLATE_VBOXBLDPROG_OBJCFLAGS.darwin    = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCFLAGS) $(VBOX_GCC_PEDANTIC_C)
+TEMPLATE_VBOXBLDPROG_OBJCXXFLAGS.darwin  = $(VBOX_DARWIN_DEF_SDK_10_6_OBJCXXFLAGS) $(VBOX_GCC_PEDANTIC_CXX)
+TEMPLATE_VBOXBLDPROG_LDFLAGS.darwin      = $(VBOX_DARWIN_DEF_SDK_10_6_LDFLAGS)
    else ifdef VBOX_MACOS_10_5_WORKAROUND # enable this if you have problems linking xpidl and is running 10.5 or later.
 TEMPLATE_VBOXBLDPROG_DEFS.darwin         = $(VBOX_DARWIN_DEF_SDK_10_5_DEFS)
 TEMPLATE_VBOXBLDPROG_CFLAGS.darwin       = $(VBOX_DARWIN_DEF_SDK_10_5_CFLAGS) -fno-common
