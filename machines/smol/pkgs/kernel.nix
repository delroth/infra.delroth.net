{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.5.5";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "1cmp2s9n35dmfb103rmnz1c563p3llxbjlv8fnqrggv9qrhaj93m";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
