{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.13.3";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "1kpj73wjs47f8fwll24snw14c4m9d6kmkkyrbn14d4mbdklnyrxb";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
