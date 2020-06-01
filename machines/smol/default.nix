{ lib, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
  };
}
