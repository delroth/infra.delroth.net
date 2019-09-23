{ lib, machineName, pkgs, ... }:

let
  my = import ../.;
in {
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

  # Add custom package set to overlays.
  nixpkgs.overlays = [ my.pkgs ];

  # Add support for command-not-found. For simplicity, hardcode a Nix channel
  # revision that has the programs.sqlite pregenerated instead of building it
  # ourselves since that's expensive.
  environment.variables.NIX_AUTO_RUN = "1";
  programs.command-not-found.dbPath = let
    channelTarball = pkgs.fetchurl {
      url = "https://releases.nixos.org/nixos/unstable/nixos-20.03pre193781.d484f2b7fc0/nixexprs.tar.xz";
      sha256 = "0aqm56p66ys3nhy19j5zbj8agfg7dyccnxgplm5kdykv22p8h4gc";
    };
  in
    pkgs.runCommand "programs.sqlite" {} ''
      tar xf ${channelTarball} --wildcards "nixos*/programs.sqlite" -O > $out
    '';
}
