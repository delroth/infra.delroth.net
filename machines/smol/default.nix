{ config, lib, pkgs, ... }:

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
    seedbox.enable = true;
    syncthing-mirror.enable = true;
    wild-eagle.enable = true;
  };

  my.homenet = {
    enable = true;
    macAddress = "f6:d4:20:6a:54:70";
    ipSuffix = 12;
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

  # TODO: Fix kernel support for apparmor
  security.apparmor.enable = false;

  # Disable module locking while working on kernel development.
  security.lockKernelModules = lib.mkForce false;
}
