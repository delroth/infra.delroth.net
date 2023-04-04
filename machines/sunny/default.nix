{ ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
    nix-builder.enable = true;
  };
}
