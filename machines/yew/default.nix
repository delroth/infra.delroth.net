{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix
    ./networking.nix

    my.common.serverBase

    my.roles.syncthingRelay
    my.roles.torRelay
  ];

  # Attempt to improve SLAB memory leak situation with a more recent kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
