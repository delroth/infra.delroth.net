{ config, nodes, pkgs, ... }:

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

      whiteboxJob = exporterName: {
        job_name = exporterName;
        scrape_interval = "10s";
        scheme = "https";
        metrics_path = "/metrics/${exporterName}";
        basic_auth = {
          username = "prometheus";
          password = my.secrets.nodeMetricsKey;
        };
        static_configs = [{
          targets =
            let
              nodesWithExporter =
                builtins.filter
                  (node: node.config.services.prometheus.exporters."${exporterName}".enable)
                  (builtins.attrValues nodes);
            in
              map
                (node: "${node.config.networking.hostName}:443")
                nodesWithExporter;
        }];
      };

    in [
      (whiteboxJob "node")
      (whiteboxJob "tor")

      (blackboxTargets {
        job_name = "http_probe";
        scrape_interval = "1m";
        modules = ["https_2xx"];
        targets = [
          "https://delroth.net"

          "https://dolphin-emu.org"
          "https://forums.dolphin-emu.org"
          "https://wiki.dolphin-emu.org"
          "https://dl.dolphin-emu.org/robots.txt"
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
