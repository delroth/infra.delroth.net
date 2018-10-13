{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts = {
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

      # Used for ACME to generate a TLS cert for the MX.
      "${config.networking.hostName}" = {
        forceSSL = true; enableACME = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
