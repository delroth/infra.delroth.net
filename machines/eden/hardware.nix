{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "ahci"
    "sd_mod"
  ];
  fileSystems."/" = {
    device = "/dev/sda";
    fsType = "ext4";
  };
  nix.settings.max-jobs = 1;

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    extraConfig = ''
      serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
      terminal_input serial;
      terminal_output serial;
    '';
  };
  boot.loader.timeout = 10;

  boot.kernelParams = [ "console=ttyS0,19200n8" ];
}
