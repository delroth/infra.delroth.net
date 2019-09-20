{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.serverBase

    my.roles.nixBuilder
    my.roles.wireguardServer
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "duke";
  };

  my.stateless = true;
  my.networking.externalInterface = "enp0s25";

  my.roles.nix-builder.enable = true;
}
