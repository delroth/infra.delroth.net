{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts = let
      withSsl = vhost: vhost // {
        forceSSL = true;
        enableACME = true;
      };
      localReverseProxy = port: withSsl {
        locations."/" = {
          proxyPass = "http://localhost:${toString port}";
        };
      };
      localRoot = root: withSsl {
        locations."/" = {
          root = "${root}";
        };
      };
    in {

      # Used for ACME to generate a TLS cert for the MX.
      "${config.networking.hostName}" = withSsl {};

      "delroth.net" = localRoot "/srv/http/public";
      "japan2018.delroth.net" = localRoot "/srv/http/japan2018";

      "mon.delroth.net" = localReverseProxy config.services.grafana.port;
      "am.delroth.net" = localReverseProxy config.services.prometheus.alertmanager.port;

      # Used to bypass CORS for https://delroth.net/publibike/
      "publibike-api.delroth.net" = withSsl {
        locations."/" = {
          proxyPass = "https://api.publibike.ch:443";
          extraConfig = ''
            proxy_set_header Host api.publibike.ch;
            proxy_set_header Origin "";
            proxy_set_header Referer "";
          '';
        };
      };

    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
