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
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  # Only 1TB/month to use :(
  services.syncthing.relay.globalRateBps = 200 * 1024;  # 200KB/s
  services.syncthing.relay.perSessionRateBps = 100 * 1024;  # 200KB/s
  services.tor.relay.accountingStart = "day 0:00";
  services.tor.relay.accountingMax = "10 GBytes";
}
