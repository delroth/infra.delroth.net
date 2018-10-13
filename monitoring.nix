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
  };

  services.grafana = {
    enable = true;
    security.secretKey = builtins.readFile ./secrets/grafana-secret-key;
  };
}
