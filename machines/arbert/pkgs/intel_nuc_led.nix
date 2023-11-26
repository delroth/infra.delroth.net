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
    rev = "master";
    sha256 = "1swpkxyn2i6xq8giqdv4pp0zv9d0hgpa77hsyadvpvvcb42f1z0x";
  };

  patches =
    [
      # proc: convert to struct proc_ops
      (fetchpatch {
        url = "https://github.com/nomego/intel_nuc_led/commit/4e0aefc83d29b9df6e10224a3f21a9c8ba91b4a5.patch";
        sha256 = "03fx1s6rhmvpnkwvyqscy2b3nxwdkdqglyvv8jyv0lfijrpbifwz";
      })
    ];

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
