let
  pkgs = import <nixpkgs> {};
in {
  blitzloop = pkgs.callPackage ./blitzloop.nix {};
  chiaki = pkgs.libsForQt5.callPackage ./chiaki.nix {};
  vim = import ./vim.nix;
}
