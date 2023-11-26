{
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation rec {
  pname = "al_nand";
  version = "${kernel.version}-master";

  src = /home/delroth/work/qnap/al_nand;

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
    install -m644 -b -D al_nand.ko $out/lib/modules/${kernel.modDirVersion}/drivers/mtd/nand/al_nand.ko
  '';
}
