{ buildLinux, fetchFromGitHub, ... }@args:

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
    kernelPatches = [ ];
  }
)
