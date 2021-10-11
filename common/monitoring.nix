{ config, lib, machineName, secrets, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "interrupts" "systemd" "tcpstat" ];
    listenAddress = "127.0.0.1";
    port = 9101;
  };

  # Define a reverse proxy configuration for Prometheus exporters to be placed
  # behind.
  services.nginx.virtualHosts = {
    "${machineName}.delroth.net" = {
      forceSSL = true;
      enableACME = true;
      basicAuth = { prometheus = secrets.nodeMetricsKey; };

      locations = builtins.listToAttrs (
        let
          enabledExporters =
            lib.filterAttrs
              (exporterName: exporter: (exporter ? enable) && exporter.enable)
              config.services.prometheus.exporters;
        in (
          lib.mapAttrsToList (
            exporterName: exporter: {
              name = "/metrics/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${toString exporter.port}/metrics";
              };
            })
            enabledExporters
        ) ++ (
          lib.mapAttrsToList (
            exporterName: exporter: {
              name = "/probe/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${toString exporter.port}/probe";
              };
            })
            enabledExporters
        ) ++ (
          lib.mapAttrsToList (
            exporterName: exporter: {
              name = "/snmp/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${toString exporter.port}/snmp";
              };
            })
            enabledExporters
        )
      );
    };
  };
}
