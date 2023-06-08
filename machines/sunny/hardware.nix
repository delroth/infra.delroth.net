{ lib, modulesPath, pkgs, nixpkgs, ... }:

let
  pkgsCross = import nixpkgs {
    system = "x86_64-linux";
    crossSystem = lib.systems.examples.aarch64-multiplatform;
  };
in {
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;
  boot.kernelPackages = pkgsCross.linuxPackages_latest;

  boot.loader.efi = {
    efiSysMountPoint = "/boot/EFI";
    canTouchEfiVariables = false;
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "noatime" "discard" ];
  };
  fileSystems."/boot/EFI" = {
    device = "/dev/disk/by-uuid/0E9E-27BC";
    fsType = "vfat";
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  nix.settings.max-jobs = lib.mkDefault 4;
}
