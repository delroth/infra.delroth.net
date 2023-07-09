{ lib, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
    nix-builder.enable = true;
    tor-relay.enable = true;
  };

  my.roles.nix-builder.speedFactor = 4;

  # This machine isn't very important.
  security.lockKernelModules = lib.mkForce false;
}
