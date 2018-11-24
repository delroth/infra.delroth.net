{ ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.serverBase

    my.roles.syncthingRelay
    my.roles.torRelay
  ];
}
