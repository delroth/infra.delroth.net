let
  pkgs = import <nixpkgs> {};
in {
  blitzloop = pkgs.callPackage ./blitzloop.nix {};
  vim = import ./vim.nix;
}
