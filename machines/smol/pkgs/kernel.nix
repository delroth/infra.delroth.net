{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "6.0.6";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    hash = "sha256-LMR8P6C5UZxC06QG3g5VebyRA1QrzUAtP31a/J32DNI=";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
