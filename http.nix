{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts = {

      "delroth.net" = {
        forceSSL = true; enableACME = true;
        locations."/" = {
          root = "/srv/http/public";
        };
      };

      "japan2018.delroth.net" = {
        forceSSL = true; enableACME = true;
        locations."/" = {
          root = "/srv/http/japan2018";
        };
      };

      "mon.delroth.net" = {
        forceSSL = true; enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.grafana.port}";
        };
      };

      "am.delroth.net" = {
        forceSSL = true; enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.prometheus.alertmanager.port}";
        };
      };

      # Used to bypass CORS for https://delroth.net/publibike/
      "publibike-api.delroth.net" = {
        forceSSL = true; enableACME = true;
        locations."/" = {
          proxyPass = "https://api.publibike.ch:443";
          extraConfig = ''
            proxy_set_header Host api.publibike.ch;
            proxy_set_header Origin "";
            proxy_set_header Referer "";
          '';
        };
      };

      # Used for ACME to generate a TLS cert for the MX.
      "${config.networking.hostName}" = {
        forceSSL = true; enableACME = true;
      };

    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
