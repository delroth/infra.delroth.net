{ lib, ... }:

{
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];

  boot.initrd.availableKernelModules = [ "ata_piix" "sym53c8xx" "uhci_hcd" "virtio_pci" "virtio_blk" ];
  boot.kernelModules = [ "kvm-intel" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  nix.maxJobs = 1;

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
}
