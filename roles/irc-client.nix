{ config, lib, pkgs, staging, ... }:

let
  cfg = config.my.roles.irc-client;
  port = 11337;
in {
  options.my.roles.irc-client = {
    enable = lib.mkEnableOption "IRC Client";
  };

  config = lib.mkIf (!staging && cfg.enable) {
    environment.systemPackages = with pkgs; [ screen weechat ];

    # TODO(delroth): Define weechat as an actual service, and configure the
    # relay port through NixOS configuration.

    services.nginx.virtualHosts."irc.delroth.net" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        root = "${pkgs.glowing-bear}";
      };

      locations."/weechat" = {
        proxyPass = "http://localhost:${toString port}/weechat";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_read_timeout 604800;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
    };
  };
}
