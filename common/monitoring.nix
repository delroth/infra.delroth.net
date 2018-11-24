{ config, machineName, staging, ... }:

let
  my = import ../.;
in {
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "interrupts" "systemd" "tcpstat" ];
    listenAddress = "127.0.0.1";
    port = 9101;
  };

  # The Prometheus node exporter doesn't support any kind of security or
  # authentication, "by design". Place it behind a reverse proxy.
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = !staging;

    virtualHosts = {
      "${machineName}.delroth.net" = {
        forceSSL = !staging;
        enableACME = !staging;
        basicAuth = { prometheus = my.secrets.nodeMetricsKey; };

        locations."/metrics/node" = {
          proxyPass =
            "http://localhost:${toString config.services.prometheus.exporters.node.port}/metrics";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
