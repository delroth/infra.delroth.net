{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles.syncthingRelay
    my.roles.torRelay
    my.roles.wireguardPeer
  ];
}
