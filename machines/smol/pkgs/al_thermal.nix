{
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation rec {
  pname = "al_thermal";
  version = "${kernel.version}-master";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "al_thermal-standalone";
    rev = "master";
    hash = "sha256-8CgOjsb7WVga84nD6YRe1OWHqjkILBPGDMt9XX+jTv8=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    cd src
    make \
        ARCH=${stdenv.hostPlatform.linuxArch} \
        CROSS_COMPILE=${stdenv.cc.targetPrefix} \
        M=$PWD \
        -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
  '';

  installPhase = ''
    install -m644 -b -D al_thermal.ko $out/lib/modules/${kernel.modDirVersion}/drivers/thermal/al_thermal.ko
  '';
}
