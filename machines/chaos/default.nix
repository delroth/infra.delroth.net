{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

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
    ./syncthing.nix
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "chaos";
  };

  my.stateless = false;

  environment.systemPackages = with pkgs; [
    wget weechat screen rsync git mailutils openssl binutils ncdu youtube-dl
    whois gnupg git-crypt my.pkgs.vim
  ];

  # Extra paths to backup.
  my.backup.extraPaths = [ "/srv" ];
}
