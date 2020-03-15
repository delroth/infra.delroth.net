{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.gaming-client;
in {
  options.my.roles.gaming-client = {
    enable = lib.mkEnableOption "Gaming client";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ chiaki runelite steam ];
    hardware.opengl.driSupport32Bit = true;
    hardware.pulseaudio.support32Bit = true;

    # Firewall ports used by Steam in-home streaming.
    networking.firewall.allowedTCPPorts = [ 27036 27037 ];
    networking.firewall.allowedUDPPorts = [ 27031 27036 ];
  };
}
