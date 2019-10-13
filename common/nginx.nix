{ config, lib, ... }:

{
  # Whenever something defines an nginx vhost, ensure that nginx defaults are
  # properly set.
  config = lib.mkIf ((builtins.attrNames config.services.nginx.virtualHosts) != []) {
    services.nginx = {
      enable = true;
      statusPage = true;  # For monitoring scraping.

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
    };

    services.prometheus.exporters.nginx = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9113;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
