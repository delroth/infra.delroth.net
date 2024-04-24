{
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  kernel,
}:

stdenv.mkDerivation rec {
  pname = "intel_nuc_led";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "nomego";
    repo = "intel_nuc_led";
    rev = "14b9b0062de3d25fd908ff86848e801f7f1001fe";
    hash = "sha256-NbQuMzrvb6ckqAiRRIO+S4Oj9DLcxz5289yvqjx0EVU=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    make \
        ARCH=${stdenv.hostPlatform.linuxArch} \
        CROSS_COMPILE=${stdenv.cc.targetPrefix} \
        M=$PWD \
        -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
  '';

  installPhase = ''
    install -m644 -b -D nuc_led.ko $out/lib/modules/${kernel.modDirVersion}/extra/nuc_led.ko
  '';
}
