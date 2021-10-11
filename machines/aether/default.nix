{ config, lib, pkgs, secrets, ... }:

let
  my = import ../..;
  kernelPackages = config.boot.kernelPackages;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.modules
  ];

  my.roles = {
    homenet-gateway = {
      enable = true;

      upstreamIface = "upstream";
      downstreamBridge = "downstream";

      homenetGatewayIp4 = "192.168.1.254";
      homenetIp4 = "192.168.1.";
      homenetIp4Cidr = 24;
      homenetDhcp4Start = "192.168.1.100";
      homenetDhcp4End = "192.168.1.200";

      homenetExtraHosts = secrets.homenet.extraHosts;
    };
    nix-builder.enable = true;
    snmp-exporter.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ethtool fio htop kernelPackages.perf kernelPackages.tmon lm_sensors
  ];

  # TODO: Fix kernel support for apparmor
  security.apparmor.enable = false;

  # Disable module locking while working on kernel development.
  security.lockKernelModules = lib.mkForce false;
}
