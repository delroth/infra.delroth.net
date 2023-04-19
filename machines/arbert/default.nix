{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./bgp-container.nix
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "eno1";

  my.roles = {
    archiveteam-warrior.enable = true;
    blackbox-prober.enable = true;
    fiber7-prober.enable = true;
    land-drake.enable = true;
    nix-builder.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.fiber7-prober.probeId = "0x30ad7256";
  my.roles.nix-builder.speedFactor = 2;

  my.homenet = {
    enable = true;
    macAddress = "54:b2:03:8d:5a:c9";
    ipSuffix = 11;
  };

  # Used as a serial host.
  boot.kernelModules = [ "ftdi_sio" "pl2303" ];
  environment.systemPackages = with pkgs; [ picocom ];

  services.atftpd.enable = true;
  networking.firewall.allowedUDPPorts = [ 69 ];

  # Home temperature monitoring.
  services.prometheus.exporters.rtl_433.enable = true;
}
