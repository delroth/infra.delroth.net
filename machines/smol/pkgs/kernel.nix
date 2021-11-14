{ buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  version = "5.13.3";
  modDirVersion = "${version}-qnap";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "linux-qnap-tsx32x";
    rev = "qnap-tsx32x";
    sha256 = "sha256-PAZ2CefvUrGDNgFeuqKj+YnVIFf4tht3g5v9rGM0B5I=";
  };

  defconfig = "qnap-tsx32x_defconfig";
  kernelPatches = [];
})
