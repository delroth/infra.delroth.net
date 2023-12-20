{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  my = import ../..;
in
{
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
    wget
    rsync
    git
    mailutils
    openssl
    binutils
    ncdu
    youtube-dl
    whois
    gnupg
    git-crypt
    vim_delroth
  ];

  services.postgresql.package = pkgs.postgresql_14;

  # Extra paths to backup.
  my.backup.extraPaths = ["/srv"];

  my.roles = {
    blackbox-prober.enable = true;
    irc-client.enable = true;
    mastodon-server.enable = true;
    matrix-client.enable = true;
    matrix-irc-bridge.enable = true;
    matrix-signal-bridge.enable = true;
    matrix-synatainer.enable = true;
    matrix-synapse.enable = true;
    music-server.enable = true;
    nix-builder.enable = true;
    publibike-locator.enable = true;
    repology-notifier.enable = true;
    smtp-server.enable = true;
    syncthing-mirror.enable = true;
    syncthing-relay.enable = true;
    tor-relay.enable = true;
    wireguard-peer.enable = true;
  };

  my.roles.nix-builder.speedFactor = 2;
  my.roles.nix-builder.systems = [
    "x86_64-linux"
    "i686-linux"
  ];

  services.label-approved = {
    enable = true;
    environmentFile = pkgs.writeText "label-approved-env" ''
      GITHUB_TOKEN=${secrets.gh-token}
    '';
  };
}
