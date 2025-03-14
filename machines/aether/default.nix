{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  my = import ../..;
  kernelPackages = config.boot.kernelPackages;
in
{
  imports = [
    ./hardware.nix
    ./networking.nix

    my.modules
  ];

  my.networking.sshPublicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtFbE83UVgyRlZQNWt1WFRkVjJGaUxjSE9zS1FZSmpVMmk3cHdXNWtRU3cgcm9vdEBhZXRoZXIK";

  my.roles = {
    homenet-gateway = {
      enable = true;

      upstreamIface = "upstream";
      downstreamBridge = "downstream";

      homenetIp6Prefix = "2a02:168:6426:";
      homenetIp6Cidr = 48;

      mainSubnet = 1;
      iotSubnet = 66;
      pubSubnet = 99;
    };
    nix-builder.enable = true;
    snmp-exporter.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ethtool
    fio
    htop
    kernelPackages.perf
    kernelPackages.tmon
    lm_sensors
  ];

  # TODO: Fix kernel support for apparmor
  security.apparmor.enable = false;

  # Disable module locking while working on kernel development.
  security.lockKernelModules = lib.mkForce false;
}
