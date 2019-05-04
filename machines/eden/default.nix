{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles.ircClient
    my.roles.syncthingRelay
    my.roles.torRelay
    my.roles.wireguardServer
  ];

  # Only 1TB/month to use :(
  services.syncthing.relay.globalRateBps = 200 * 1024;  # 200KB/s
  services.syncthing.relay.perSessionRateBps = 100 * 1024;  # 200KB/s
  services.tor.relay.accountingStart = "day 0:00";
  services.tor.relay.accountingMax = "10 GBytes";
}
