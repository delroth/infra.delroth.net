{ config, lib, ... }:

let
  cfg = config.my.roles.music-server;

  hostname = "music.delroth.net";
  port = 4040;
in
{
  options.my.roles.music-server = {
    enable = lib.mkEnableOption "Music server";
  };

  config = lib.mkIf cfg.enable {
    services.airsonic = {
      enable = true;
      home = "/srv/airsonic";
      virtualHost = hostname;
    };

    services.nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;
    };
  };
}
