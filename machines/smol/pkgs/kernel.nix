{ buildLinux, fetchFromGitHub, fetchpatch, ... }@args:

buildLinux (
  args
  // rec {
    version = "6.0.6";
    modDirVersion = "${version}-qnap";

    src = fetchFromGitHub {
      owner = "delroth";
      repo = "linux-qnap-tsx32x";
      rev = "old-6.0.6";
      hash = "sha256-XjmjFKDWCqMw7lK1nsQ50f4cxdqklMRRdhDo7tDerM8=";
    };

    defconfig = "qnap-tsx32x_defconfig";
    ignoreConfigErrors = true;
  }
)
