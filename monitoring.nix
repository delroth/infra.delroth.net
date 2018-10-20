{ config, pkgs, ... }:

{
  services.prometheus = rec {
    enable = true;

    exporters.node = {
      enable = true;
      enabledCollectors = [ "interrupts" "systemd" "tcpstat" ];
      port = 9100;
    };
    exporters.tor = {
      enable = true;
      torControlPort = config.services.tor.controlPort;
      port = 9130;
    };

    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          { targets = ["127.0.0.1:${toString exporters.node.port}"]; }
        ];
      }
      {
        job_name = "tor";
        scrape_interval = "10s";
        static_configs = [
          { targets = ["127.0.0.1:${toString exporters.tor.port}"]; }
        ];
      }
    ];

    alertmanager = {
      enable = true;

      listenAddress = "127.0.0.1";
      port = 9093;
      webExternalUrl = "https://am.delroth.net";

      # AM clustering doesn't like when the machine doesn't have an RFC1918 IP.
      extraFlags = [
        "--cluster.listen-address=''"
      ];

      configuration = {
        global = {
          smtp_smarthost = "127.0.0.1:25";
          smtp_from = "alerts@chaos.delroth.net";
          smtp_require_tls = false;
        };

        route = {
          receiver = "email";
        };

        receivers = [
          {
            name = "email";
            email_configs = [ { to = "delroth+chaos-alerts@gmail.com"; } ];
          }
        ];
      };
    };
    alertmanagerURL = [ "http://${alertmanager.listenAddress}:${toString alertmanager.port}" ];

    ruleFiles = [ ./monitoring.rules ];
  };

  services.grafana = {
    enable = true;
    security.secretKey = builtins.readFile ./secrets/grafana-secret-key;
  };
}
