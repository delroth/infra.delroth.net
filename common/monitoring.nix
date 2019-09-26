{ config, lib, machineName, secrets, staging, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "interrupts" "systemd" "tcpstat" ];
    listenAddress = "127.0.0.1";
    port = 9101;
  };

  # Define a reverse proxy configuration for Prometheus exporters to be placed
  # behind.
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = !staging;

    virtualHosts = {
      "${machineName}.delroth.net" = {
        forceSSL = !staging;
        enableACME = !staging;
        basicAuth = { prometheus = secrets.nodeMetricsKey; };

        locations = builtins.listToAttrs (
          let
            enabledExporters =
              lib.filterAttrs
                (exporterName: exporter: (exporter ? enable) && exporter.enable)
                config.services.prometheus.exporters;
          in
            lib.mapAttrsToList (
              exporterName: exporter: {
                name = "/metrics/${exporterName}";
                value = {
                  proxyPass = "http://localhost:${toString exporter.port}/metrics";
                };
              })
              enabledExporters
        );
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
