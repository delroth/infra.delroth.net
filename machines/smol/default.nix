{ config, pkgs, ... }:

let
  my = import ../..;
  kernelPackages = config.boot.kernelPackages;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
    file-server = {
      enable = true;
      root = "/data";
      shareName = "data";
    };
  };

  # Remove a few non-essentials to avoid having to build LLVM and Spidermonkey.
  security.apparmor.enable = false;
  security.polkit.enable = false;
  services.udisks2.enable = false;

  # ZFS configuration.
  boot.supportedFilesystems = [ "zfs" ];
  fileSystems."/data" = {
    device = "ds/data";
    fsType = "zfs";
  };
  services.zfs.autoScrub.enable = true;
  environment.systemPackages = with pkgs; [
    fio kernelPackages.tmon lm_sensors screen sysstat
  ];

  # SMART monitoring.
  services.smartd = {
    enable = true;
    notifications = {
      mail.enable = true;
      test = true;
    };
  };
}
