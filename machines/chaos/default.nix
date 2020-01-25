{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.modules

    # TODO: Move most of these to generic roles.
    ./dns.nix
    ./http.nix
    ./monitoring.nix
    ./networking.nix
  ];

  my.stateless.enable = false;

  environment.systemPackages = with pkgs; [
    wget rsync git mailutils openssl binutils ncdu youtube-dl
    whois gnupg git-crypt vim_delroth
  ];

  # Extra paths to backup.
  my.backup.extraPaths = [ "/srv" ];

  my.roles = {
    blackbox-prober.enable = true;
    iot-gateway.enable = true;
    irc-client.enable = true;
    matrix-synapse.enable = true;
    music-server.enable = true;
    nix-builder.enable = true;
    publibike-locator.enable = true;
    smtp-server.enable = true;
    syncthing-mirror.enable = true;
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.nix-builder.speedFactor = 2;
}
