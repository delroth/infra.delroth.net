{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.11.15";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "08vznjal7bvywizaz3l7pqj7na7qjdmkspdbls2rm93rczfzy5wj";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
