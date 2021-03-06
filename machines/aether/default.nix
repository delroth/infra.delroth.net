{ config, lib, pkgs, ... }:

let
  my = import ../..;
  kernelPackages = config.boot.kernelPackages;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
    nix-builder.enable = true;
  };

  environment.systemPackages = with pkgs; [
    fio htop kernelPackages.perf kernelPackages.tmon lm_sensors
  ];

  # TODO: Fix kernel support for apparmor
  security.apparmor.enable = false;

  # Disable module locking while working on kernel development.
  security.lockKernelModules = lib.mkForce false;
}
