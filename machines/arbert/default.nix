{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "enp5s0";
  my.networking.pmp.publicPorts = [ 143 ];

  my.roles = {
    fiber7-prober.enable = true;
    fifoci-worker.enable = true;
    nix-builder.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.fiber7-prober.probeId = "0x30ad7256";
  my.roles.fifoci-worker.info = "Intel NUC8i7HVK, NixOS unstable";
  my.roles.nix-builder.speedFactor = 2;

  # Used as a serial host.
  boot.kernelModules = [ "ftdi_sio" "pl2303" ];
  environment.systemPackages = with pkgs; [ picocom ];

  services.atftpd.enable = true;
  networking.firewall.allowedUDPPorts = [ 69 ];

  # Home temperature monitoring.
  services.prometheus.exporters.rtl_433.enable = true;
}
