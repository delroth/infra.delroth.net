{ config, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles.torRelay

    # TODO: Move most of these to generic roles.
    ./dns.nix
    ./email.nix
    ./http.nix
    ./ipfs.nix
    ./monitoring.nix
    ./networking.nix
    ./syncthing.nix
  ];

  environment.systemPackages = with pkgs; [
    wget weechat screen rsync git mailutils openssl binutils ncdu youtube-dl
    whois gnupg git-crypt my.pkgs.vim
  ];
}
