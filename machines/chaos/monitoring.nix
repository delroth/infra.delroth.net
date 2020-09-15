{ config, nodes, pkgs, secrets, ... }:

{
  services.prometheus = rec {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 9090;
    webExternalUrl = "https://prom.delroth.net/";

    scrapeConfigs = let

      baseScrapeConfig = {
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password = secrets.nodeMetricsKey;
        };
      };

      blackboxTargets = {job_name, scrape_interval, modules, targets}: let
        hasBlackbox = node:
            node.config.services.prometheus.exporters.blackbox.enable;
        exporterNodes =
            builtins.filter hasBlackbox (builtins.attrValues nodes);
        exporters =
            map (n: "${n.config.my.networking.fqdn}:443") exporterNodes;
      in baseScrapeConfig // {
        job_name = job_name;
        scrape_interval = scrape_interval;
        metrics_path = "/probe/blackbox";
        params = {
          module = modules;
        };
        static_configs = map (t: {
          targets = exporters;
          labels.target = t;
        }) targets;
        relabel_configs = [
          { source_labels = [ "target" ]; target_label = "__param_target"; }
        ];
      };

      whiteboxJob = exporterName: baseScrapeConfig // {
        job_name = exporterName;
        scrape_interval = "10s";
        metrics_path = "/metrics/${exporterName}";
        static_configs = let
          hasExporter = node:
              node.config.services.prometheus.exporters."${exporterName}".enable;

          nodesWithExporter =
              builtins.filter hasExporter (builtins.attrValues nodes);

          nodeIsRoaming = node: node.config.my.laptop.enable;
          partByRoaming = builtins.partition nodeIsRoaming nodesWithExporter;

          nodeTarget = node: "${node.config.my.networking.fqdn}:443";
          roamingTargets = map nodeTarget partByRoaming.right;
          nonRoamingTargets = map nodeTarget partByRoaming.wrong;
        in [
          { targets = roamingTargets; labels = { roaming = "true"; }; }
          { targets = nonRoamingTargets; labels = { roaming = "false"; }; }
        ];
      };

    in [
      (whiteboxJob "nginx")
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
          "https://dolp.in"
        ];
      })

      (blackboxTargets {
        job_name = "smtp_probe";
        scrape_interval = "1m";
        modules = ["smtp_starttls"];
        targets = [
          "chaos.delroth.net:25"
        ];
      })

      {
        job_name = "hass";
        scrape_interval = "1m";
        scheme = "https";
        metrics_path = "/api/prometheus";
        bearer_token = secrets.iot.token;
        static_configs = [{ targets = [ "hass.delroth.net:443" ]; }];
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

    alertmanagers = [{
      static_configs = [{
        targets = [ "${alertmanager.listenAddress}:${toString alertmanager.port}" ];
      }];
    }];

    ruleFiles = [ ./monitoring.rules ];
  };

  services.grafana = {
    enable = true;
    domain = "mon.delroth.net";
    rootUrl = "https://mon.delroth.net/";
    security.secretKey = secrets.grafanaSecretKey;
    extraOptions = {
      AUTH_PROXY_ENABLED = "true";
      AUTH_PROXY_HEADER_NAME = "X-User";
    };
  };
}
