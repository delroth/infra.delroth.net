{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

let
  pkgsCross = import nixpkgs {
    system = "x86_64-linux";
    crossSystem = lib.systems.examples.aarch64-multiplatform;
  };

  restool = pkgs.restool.overrideAttrs (
    final: prev: {
      version = "2.3";

      src = pkgs.fetchgit {
        url = "https://github.com/nxp-qoriq/restool";
        rev = "f0cec094e4c6d1c975b377203a3bf994ba9325a9";
        hash = "sha256-BdHdG+jjxJJJlFdCEtySCcj2GcnUqM7lgaHE5yRm86k=";
      };

      patches = (prev.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/nxp-qoriq/restool/commit/802764f8ed76f927dff494558332b0b77de7ac65.patch";
          hash = "sha256-3/zyeJOBGRtSmYqPlAwE770Nyyc+vPNC2vDCWGjdd5Q=";
        })
      ];
    }
  );
in
{
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;

  # Use the latest (5.14+) kernel for proper hardware support. Cross-compile
  # for more build capacity.
  boot.kernelPackages = pkgsCross.linuxPackages_latest;

  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "earlycon=pl011,mmio32,0x21c0000"
    "pci=pcie_bus_perf"
    "arm-smmu.disable_bypass=0"
    "iommu.passthrough=1"
    "mitigations=off" # Significant performance boost, not multi-user.
    "pcie_aspm=off"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup SFP+ network interfaces early so systemd can pick everything up.
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${restool}/bin/restool
    copy_bin_and_libs ${restool}/bin/ls-main
    copy_bin_and_libs ${restool}/bin/ls-addni

    # Patch paths
    sed -i "1i #!$out/bin/sh" $out/bin/ls-main
  '';
  boot.initrd.postDeviceCommands = ''
    ls-addni dpmac.7
    ls-addni dpmac.8
    ls-addni dpmac.9
    ls-addni dpmac.10
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
    options = [
      "noatime"
      "discard"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  nix.settings.max-jobs = lib.mkDefault 16;

  services.apcupsd.enable = true;
  services.prometheus.exporters.apcupsd = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  systemd.watchdog.device = "/dev/watchdog";
  systemd.watchdog.runtimeTime = "30s";
  systemd.watchdog.rebootTime = "30s";
}
