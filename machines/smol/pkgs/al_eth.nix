{
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation rec {
  pname = "al_eth";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "al_eth-standalone";
    rev = "master";
    hash = "sha256-oqXiqJ3/8rdiUQgjKjcDYj2s69edT0w5gH2JBjIenKs=";
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
