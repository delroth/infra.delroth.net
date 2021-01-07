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
    nix-builder.enable = true;
    seedbox.enable = true;
    syncthing-mirror.enable = true;
    wild-eagle.enable = true;
  };

  # ZFS configuration.
  boot.supportedFilesystems = [ "zfs" ];
  fileSystems."/data" = {
    device = "ds/data";
    fsType = "zfs";
  };
  services.zfs.autoScrub.enable = true;
  environment.systemPackages = with pkgs; [
    fio gdb kernelPackages.perf kernelPackages.tmon lm_sensors screen sysstat
  ];

  # SMART monitoring.
  services.smartd = {
    enable = true;
    notifications = {
      mail.enable = true;
    };
  };
}
