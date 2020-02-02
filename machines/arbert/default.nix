{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "enp5s0";
  my.networking.external6 = "2a02:168:6426::3ac";

  my.roles = {
    fiber7-prober.enable = true;
    fifoci-worker.enable = true;
    nix-builder.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.fiber7-prober.probeId = "0x30ad7256";
  my.roles.fifoci-worker.info = "Intel NUC8i7HVK, NixOS unstable";
  my.roles.nix-builder.speedFactor = 2;
}
