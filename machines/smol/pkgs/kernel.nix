{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.13.3";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "1y3f6my4h0yl6022jhqlkpdm3cynd4qns3yr8glpklbfa2a8a933";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
