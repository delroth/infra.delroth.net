{ stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "al_eth";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "al_eth-standalone";
    rev = "master";
    sha256 = "0yyhwwlqhqzi9x7rxm56hx8vypzhdpf1z5snn6d3iakyqm1h9yg1";
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
