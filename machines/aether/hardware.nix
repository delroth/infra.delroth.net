{ config, lib, pkgs, ... }:

{
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;

  # Use the vendor kernel.
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.buildLinux {
    src = pkgs.fetchFromGitHub {
      owner = "SolidRun";
      repo = "linux-stable";
      rev = "bc1160fd43de6bc9a09e25c027a057e1376e5b9a";
      sha256 = "1cq36vpsd68g144gn7f3jjkl2bwibqv7nrrrjgvkdj1lfijcwm14";
    };
    version = "5.10.5";
    kernelPatches = [ ];
    structuredExtraConfig = with pkgs.lib.kernel; {
      CGROUP_FREEZER = yes;
    };
  }));

  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.kernelParams = [
      "console=ttyAMA0,115200"
      "earlycon=pl011,mmio32,0x21c0000"
      "pci=pcie_bus_perf"
      "arm-smmu.disable_bypass=0"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
