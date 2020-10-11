{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.7.2";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "5e6bbb3151d7cee2b89da8b9735488761d9eafdf";
    sha256 = "1hx2fd86zdia6mzgxx8xilsiv90dam4sd7ibis3z7ils8sz1vvwz";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
