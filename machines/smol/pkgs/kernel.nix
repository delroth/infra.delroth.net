{ buildLinux, fetchFromGitHub, ... }@args:

buildLinux (
  args
  // rec {
    version = "6.0.6";
    modDirVersion = "${version}-qnap";

    src = fetchFromGitHub {
      owner = "delroth";
      repo = "linux-qnap-tsx32x";
      rev = "qnap-tsx32x";
      hash = "sha256-XjmjFKDWCqMw7lK1nsQ50f4cxdqklMRRdhDo7tDerM8=";
    };

    defconfig = "qnap-tsx32x_defconfig";
    kernelPatches = [ ];
  }
)
