{
  config,
  lib,
  machineName,
  secrets,
  ...
}:

{
  options.my.monitoring = with lib; {
    roaming = mkOption {
      description = "Set this host as roaming, aka. it might be down sometimes";
      default = false;
      type = types.bool;
    };
  };

  config = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "interrupts"
        "systemd"
        "tcpstat"
      ];
      listenAddress = "127.0.0.1";
      port = 9101;
    };

    # Define a reverse proxy configuration for Prometheus exporters to be placed
    # behind.
    services.nginx.virtualHosts = {
      "${machineName}.delroth.net" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = {
          prometheus = secrets.nodeMetricsKey;
        };

        locations = builtins.listToAttrs (
          let
            enabledExporters =
              lib.filterAttrs (exporterName: exporter: (exporter ? enable) && exporter.enable)
                (lib.removeAttrs config.services.prometheus.exporters [
                  "minio"
                  "tor"
                  "unifi-poller"
                ]);
          in
          (lib.mapAttrsToList
            (exporterName: exporter: {
              name = "/metrics/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${exporter.port}/metrics";
              };
            })
            enabledExporters
          )
          ++ (lib.mapAttrsToList
            (exporterName: exporter: {
              name = "/probe/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${exporter.port}/probe";
              };
            })
            enabledExporters
          )
          ++ (lib.mapAttrsToList
            (exporterName: exporter: {
              name = "/snmp/${exporterName}";
              value = {
                proxyPass = "http://127.0.0.1:${exporter.port}/snmp";
              };
            })
            enabledExporters
          )
        );
      };
    };
  };
}
