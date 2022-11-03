{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "6.0.6";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    hash = "sha256-4D4RE7WZBp3HzZWO7vmCQBcXsphat0Dk8YrX/u/KHkU=";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
