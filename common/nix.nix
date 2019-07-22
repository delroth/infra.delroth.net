{ lib, machineName, pkgs, ... }:

{
  nix.autoOptimiseStore = true;
  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = true;
    nixos.enable = false;
  };
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  nix.trustedUsers = [ "root" "@wheel" ];

  nix.daemonNiceLevel = 10;
  nix.daemonIONiceLevel = 5;

  # Support using nix-shell for temporary package installs on infra machines.
  environment.etc.nixpkgs.source = lib.cleanSource pkgs.path;
  nix.nixPath = [ "nixpkgs=/etc/nixpkgs" ];
}
