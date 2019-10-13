{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles
  ];

  my.roles = {
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };
}
