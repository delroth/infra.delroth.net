{ lib, machineName, pkgs, ... }:

let
  my = import ../.;
in {
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command
  '';

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

  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # Support using nix-shell for temporary package installs on infra machines.
  environment.etc.nixpkgs.source = lib.cleanSource pkgs.path;
  nix.nixPath = [ "nixpkgs=/etc/nixpkgs" ];

  # Add custom package set to overlays.
  nixpkgs.overlays = [ my.pkgs my.secrets.pkgs ];

  # Add support for command-not-found. For simplicity, hardcode a Nix channel
  # revision that has the programs.sqlite pregenerated instead of building it
  # ourselves since that's expensive.
  environment.variables.NIX_AUTO_RUN = "1";
  programs.command-not-found.dbPath = let
    channelTarball = pkgs.fetchurl {
      url = "https://releases.nixos.org/nixos/unstable/nixos-21.05pre275822.916ee862e87/nixexprs.tar.xz";
      sha256 = "0zg4crz5i01myblc7jf87rk6ql1ymf0q4j6babkmaa7r7ichsghs";
    };
  in
    pkgs.runCommand "programs.sqlite" {} ''
      tar xf ${channelTarball} --wildcards "nixos*/programs.sqlite" -O > $out
    '';

  # Inject secrets through module arguments while evaluating configs.
  _module.args.secrets = my.secrets;
}
