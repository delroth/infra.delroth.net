{ buildLinux, fetchFromGitHub, fetchpatch, ... }@args:

buildLinux (
  args
  // rec {
    version = "6.12.12";
    modDirVersion = "${version}-qnap";

    src = fetchFromGitHub {
      owner = "delroth";
      repo = "linux-qnap-tsx32x";
      rev = "qnap-tsx32x";
      hash = "sha256-zGr41HenrgQZ3beLjp4kk2mU7nr9T/NT0nPAZSn4MDQ=";
    };

    defconfig = "qnap-tsx32x_defconfig";
    kernelPatches = [
      {
        name = "drm-panic-rust-compile-fix";
        patch = ./drm-panic-rust-compile-fix.patch;
      }
    ];
    ignoreConfigErrors = true;
  }
)
