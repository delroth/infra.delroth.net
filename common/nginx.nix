{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    statusPage = true; # For monitoring scraping.

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedZstdSettings = true;

    package = pkgs.nginxQuic;
  };

  services.prometheus.exporters.nginx = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9113;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
