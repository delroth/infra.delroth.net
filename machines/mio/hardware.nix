{ lib, ... }:

{
  boot.initrd.availableKernelModules = [ "sd_mod" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/665806a9-4b36-4e37-ab5e-f4db07378edf";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1003-E38A";
    fsType = "vfat";
  };

  boot.loader.systemd-boot.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;

  virtualisation.hypervGuest.enable = true;
}
