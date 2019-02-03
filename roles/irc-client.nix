{ lib, pkgs, staging, ... }:

let
  port = 11337;
in {
  config = lib.mkIf (!staging) {
    environment.systemPackages = with pkgs; [ screen weechat ];

    # TODO(delroth): Define weechat as an actual service, and configure the
    # relay port through NixOS configuration.

    services.nginx.virtualHosts."irc.delroth.net" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
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
