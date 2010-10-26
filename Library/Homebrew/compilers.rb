RECOMMENDED_LLVM = 2326
RECOMMENDED_GCC_40 = (MACOS_VERSION >= 10.6) ? 5494 : 5493
RECOMMENDED_GCC_42 = (MACOS_VERSION >= 10.6) ? 5664 : 5577


def gcc_42_build
  `/usr/bin/gcc-4.2 -v 2>&1` =~ /build (\d{4,})/
  if $1
    $1.to_i 
  elsif system "/usr/bin/which gcc"
    # Xcode 3.0 didn't come with gcc-4.2
    # We can't change the above regex to use gcc because the version numbers
    # are different and thus, not useful.
    # FIXME I bet you 20 quid this causes a side effect — magic values tend to
    401
  else
    nil
  end
end

def gcc_40_build
  `/usr/bin/gcc-4.0 -v 2>&1` =~ /build (\d{4,})/
  if $1
    $1.to_i 
  else
    nil
  end
end

def llvm_build
  if MACOS_VERSION >= 10.6
    xcode_path = `/usr/bin/xcode-select -print-path`.chomp
    return nil if xcode_path.empty?
    `#{xcode_path}/usr/bin/llvm-gcc -v 2>&1` =~ /LLVM build (\d{4,})/
    $1.to_i
  end
end

def xcode_version
  `xcodebuild -version 2>&1` =~ /Xcode (\d(\.\d)*)/
  return $1 ? $1 : nil
end

def check_for_compilers
  begin
    if MACOS_VERSION >= 10.6
      if llvm_build < RECOMMENDED_LLVM
        opoo "You should upgrade to Xcode 3.2.3"
      end
    else
      if (gcc_40_build < RECOMMENDED_GCC_40) or (gcc_42_build < RECOMMENDED_GCC_42)
        opoo "You should upgrade to Xcode 3.1.4"
      end
    end
  rescue
    # the reason we don't abort is some formula don't require Xcode
    # TODO allow formula to declare themselves as "not needing Xcode"
    opoo "Xcode is not installed! Builds may fail!"
  end
end
