{ config, pkgs, ... }:

let
  my = import ../..;
in {
  services.prometheus = rec {
    enable = true;

    listenAddress = "127.0.0.1:9090";
    webExternalUrl = "https://prom.delroth.net/";

    exporters.blackbox = {
      enable = true;
      port = 9115;
      configFile = ./blackbox.yml;
    };
    exporters.node = {
      enable = true;
      enabledCollectors = [ "interrupts" "systemd" "tcpstat" ];
      port = 9100;
    };
    exporters.tor = {
      enable = true;
      torControlPort = config.services.tor.controlPort;
      listenAddress = "127.0.0.1";
      port = 9130;
    };

    scrapeConfigs = let

      blackboxTargets = {job_name, scrape_interval, modules, targets}: {
        job_name = job_name;
        scrape_interval = scrape_interval;
        metrics_path = "/probe";
        params = {
          module = modules;
        };
        static_configs = [
          { targets = targets; }
        ];
        relabel_configs = [
          { source_labels = [ "__address__" ]; target_label = "__param_target"; }
          { source_labels = [ "__param_target" ]; target_label = "instance"; }
          { source_labels = []; target_label = "__address__";
            replacement = "127.0.0.1:${toString exporters.blackbox.port}"; }
        ];
      };

    in [
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

      (blackboxTargets {
        job_name = "http_probe";
        scrape_interval = "1m";
        modules = ["http_2xx"];
        targets = [
          "https://delroth.net"
          "https://home.delroth.net"

          "https://dolphin-emu.org"
          "https://forums.dolphin-emu.org"
          "https://wiki.dolphin-emu.org"
          "https://dl.dolphin-emu.org"
        ];
      })
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
    security.secretKey = my.secrets.grafanaSecretKey;
    extraOptions = {
      AUTH_PROXY_ENABLED = "true";
      AUTH_PROXY_HEADER_NAME = "X-User";
    };
  };
}
