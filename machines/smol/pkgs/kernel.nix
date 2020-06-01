{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.5.5";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "1fzfbfdiy37yzqa5faxq79avcf8x8pm1w2wzsd3dkybxavmq07km";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
