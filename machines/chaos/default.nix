{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles.iotGateway
    my.roles.ircClient
    my.roles.matrixSynapse
    my.roles.nixBuilder
    my.roles.syncthingMirror
    my.roles.syncthingRelay
    my.roles.torRelay
    my.roles.wireguardServer

    # TODO: Move most of these to generic roles.
    ./dns.nix
    ./email.nix
    ./http.nix
    ./ipfs.nix
    ./monitoring.nix
    ./networking.nix
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "chaos";
  };

  my.stateless = false;

  environment.systemPackages = with pkgs; [
    wget rsync git mailutils openssl binutils ncdu youtube-dl
    whois gnupg git-crypt vim_delroth
  ];

  # Extra paths to backup.
  my.backup.extraPaths = [ "/srv" ];

  my.roles.iot-gateway.enable = true;
  my.roles.nix-builder.enable = true;
  my.roles.syncthing-mirror.enable = true;
}
