{
  config,
  lib,
  pkgs,
  ...
}:

let
  my = import ../..;
  kernelPackages = config.boot.kernelPackages;
in
{
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.sshPublicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUQ5VGE0RFlFM1l4WHpWNTdzNlRYNktFYklhM080cmUrSjROekFUQ09pWGIgcm9vdEBzbW9sCg==";

  my.roles = {
    backup-receiver.enable = true;
    nas = {
      enable = true;
      root = "/data";
      shareName = "data";
    };
    s3 = {
      enable = true;
      dataRoot = "/data/s3";
    };
    seedbox.enable = true;
    syncthing-mirror.enable = true;
    wild-eagle.enable = true;
  };

  my.homenet = {
    enable = true;
    macAddress = "96:cd:58:c1:a9:a8";
    ipSuffix = 12;
  };

  # Network configuration.
  networking.useDHCP = false;
  networking.interfaces.enp0s2.useDHCP = true;

  # QNAP didn't bother registering OUIs for the MAC address burned into the
  # NIC, which means they're not considered global. This causes Kea to ignore
  # the LL addresses when trying to locate the MAC address to match the DHCP
  # reservation. Change DUID type to one that is MAC based to simplify.
  systemd.network.networks."40-enp0s2".dhcpV6Config.DUIDType = "link-layer";

  # ZFS configuration.
  boot.supportedFilesystems = [ "zfs" ];
  fileSystems."/data" = {
    device = "ds/data";
    fsType = "zfs";
  };
  services.zfs.autoScrub.enable = true;
  environment.systemPackages = with pkgs; [
    fio
    gdb
    kernelPackages.perf
    kernelPackages.tmon
    lm_sensors
    screen
    sysstat
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
