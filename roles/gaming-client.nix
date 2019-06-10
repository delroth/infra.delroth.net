{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.gaming-client;
in {
  options.my.roles.gaming-client = {
    enable = lib.mkEnableOption "Gaming client";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ runelite steam ];
    hardware.opengl.driSupport32Bit = true;
    hardware.pulseaudio.support32Bit = true;
  };
}
