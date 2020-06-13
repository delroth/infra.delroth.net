{ stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "al_eth";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "al_eth-standalone";
    rev = "master";
    sha256 = "13cb43lhlwhhx9k6g0dzpjgq4a9pi1v9lq66rhaqwfwgpai3c2bm";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    cd src
    make \
        ARCH=${stdenv.hostPlatform.platform.kernelArch} \
        CROSS_COMPILE=${stdenv.cc.targetPrefix} \
        M=$PWD \
        -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
  '';

  installPhase = ''
    install -m644 -b -D al_eth.ko $out/lib/modules/${kernel.modDirVersion}/drivers/net/ethernet/al_eth.ko
  '';
}
