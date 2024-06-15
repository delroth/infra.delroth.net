{ pkgs, ... }:

let
  my = import ../..;
in
{
  imports = [
    ./hardware.nix
    ./networking.nix

    my.modules
  ];

  my.networking.sshPublicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU1DYWpiOVNDVEVSM1dBUmF1VWU0TytqbFNnNmRUUEZneElBRXM5bVpLKzAgcm9vdEBlZGVuLmRlbHJvdGgubmV0Cg==";

  my.roles = {
    blackbox-prober.enable = true;
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  # Only 1TB/month to use :(
  services.syncthing.relay.globalRateBps = 200 * 1024; # 200KB/s
  services.syncthing.relay.perSessionRateBps = 100 * 1024; # 200KB/s
  services.tor.settings.AccountingStart = "day 0:00";
  services.tor.settings.AccountingMax = "10 GBytes";
}
