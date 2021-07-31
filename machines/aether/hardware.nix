{ config, lib, pkgs, ... }:

{
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;

  # Use the vendor kernel.
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.buildLinux {
    src = pkgs.fetchFromGitHub {
      owner = "SolidRun";
      repo = "linux-stable";
      rev = "linux-5.12.y-cex7";
      sha256 = "16p67q623adyakjpyrx10pxglvdwdvxkwkkfgmlqlpbk0ps8j2jk";
    };
    version = "5.12.17";
    kernelPatches = [ ];
    structuredExtraConfig = with pkgs.lib.kernel; {
      CGROUP_FREEZER = yes;
      EFI_GENERIC_STUB_INITRD_CMDLINE_LOADER = yes;
      FSL_MC_UAPI_SUPPORT = yes;
    };
  }));

  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.kernelParams = [
      "console=ttyAMA0,115200"
      "earlycon=pl011,mmio32,0x21c0000"
      "pci=pcie_bus_perf"
      "arm-smmu.disable_bypass=0"
      "iommu.passthrough=1"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup SFP+ network interfaces early so systemd can pick everything up.
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.restool}/bin/restool
    copy_bin_and_libs ${pkgs.restool}/bin/ls-main
    copy_bin_and_libs ${pkgs.restool}/bin/ls-addni

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
    options = [ "noatime" "discard" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  nix.maxJobs = lib.mkDefault 16;
}
