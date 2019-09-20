{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    my.common.serverBase

    <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>
    <nixpkgs/nixos/modules/installer/scan/detected.nix>
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "nixos-installer";
  };

  deployment.buildOnly = true;
  my.stateless = false;
  networking.wireless.networks = my.secrets.wirelessNetworks;
  services.mingetty.autologinUser = "delroth";

  isoImage = {
    isoBaseName = "delroth-nixos-installer";
    makeEfiBootable = true;
    makeUsbBootable = true;
    volumeID = "DELROTH_NIXOS_ISO";
  };
}
