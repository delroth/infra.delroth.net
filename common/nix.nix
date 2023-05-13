{ lib, machineName, pkgs, ... }:

let
  my = import ../.;

  secrets = my.secrets { inherit pkgs; };
in {
  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = true;
    nixos.enable = false;
  };

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # Support using nix-shell for temporary package installs on infra machines.
  environment.etc.nixpkgs.source = lib.cleanSource pkgs.path;
  nix.nixPath = [ "nixpkgs=/etc/nixpkgs" ];

  # Add custom package set to overlays.
  nixpkgs.overlays = [ my.pkgs secrets.pkgs ];

  # Add support for command-not-found. For simplicity, hardcode a Nix channel
  # revision that has the programs.sqlite pregenerated instead of building it
  # ourselves since that's expensive.
  environment.variables.NIX_AUTO_RUN = "1";
  programs.command-not-found.dbPath = let
    channelTarball = pkgs.fetchurl {
      url = "https://releases.nixos.org/nixos/unstable/nixos-22.05pre358986.062a0c5437b/nixexprs.tar.xz";
      sha256 = "sha256-ca8tlBaVowbYJKoHQb8T4FdYccaGODeKPdEz/L0EbJM=";
    };
  in
    pkgs.runCommand "programs.sqlite" {} ''
      tar xf ${channelTarball} --wildcards "nixos*/programs.sqlite" -O > $out
    '';

  # Inject secrets through module arguments while evaluating configs.
  _module.args.secrets = secrets;
}
