{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.modules
  ];

  my.roles = {
    blackbox-prober.enable = true;
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };
}
