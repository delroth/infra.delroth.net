{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "enp5s0";

  my.roles = {
    fifoci-worker.enable = true;
    nix-builder.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.nix-builder.speedFactor = 2;
}
