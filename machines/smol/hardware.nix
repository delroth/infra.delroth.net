{ config, lib, pkgs, ... }:

let
  # Use cross-compiled kernel packages to make builds faster.
  kernelPackages = import ./kernel.nix { inherit pkgs; };
in {
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;

  boot.kernelPackages = lib.mkForce kernelPackages;
  boot.extraModulePackages = [
    kernelPackages.al_eth
    kernelPackages.al_thermal
  ];
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlycon"
    "panic=3"
  ];
  boot.kernelModules = [
    "drivetemp"  # For drive temperature monitoring.
  ];

  networking.hostId = "ca504f8f";

  boot.loader.grub.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
    options = [ "noatime" "discard" ];
  };

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
