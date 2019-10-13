{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "enp0s25";

  my.roles = {
    nix-builder.enable = true;
    wireguard-peer.enable = true;
  };
}
