{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.serverBase

    my.roles
  ];

  my.stateless = true;
  my.networking.externalInterface = "enp0s25";

  my.roles = {
    nix-builder.enable = true;
    wireguard-peer.enable = true;
  };
}
