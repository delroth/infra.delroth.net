{ lib, ... }:

let
  my = import ../..;
in
{
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.sshPublicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUwyRmpDY3JvNWdKYmVXUDBUck9nZWtacWl2cWZZTFpHbkF2T08vNi9yMkcgcm9vdEBpbnN0YW5jZS0yMDIyMTEwMy0wNDAwCg==";

  my.roles = {
    nix-builder.enable = true;
    tor-relay.enable = true;
  };

  my.roles.nix-builder.speedFactor = 4;

  # This machine isn't very important.
  security.lockKernelModules = lib.mkForce false;
}
