{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "ehci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/vda";
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b966ba1a-ec1e-497c-9c2f-86e1c13c5bf1";
      fsType = "ext4";
    };

  nix.settings.max-jobs = lib.mkDefault 4;
}
