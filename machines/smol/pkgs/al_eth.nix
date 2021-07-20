{ stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "al_eth";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "al_eth-standalone";
    rev = "master";
    sha256 = "0jazj2kqk6gg3117q7jyggk4fpj55fn1fl7vi0fkwc03z5la7jcx";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    cd src
    make \
        ARCH=${stdenv.hostPlatform.linuxArch} \
        CROSS_COMPILE=${stdenv.cc.targetPrefix} \
        M=$PWD \
        -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
        -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    install -m644 -b -D al_eth.ko $out/lib/modules/${kernel.modDirVersion}/drivers/net/ethernet/al_eth.ko
  '';
}
