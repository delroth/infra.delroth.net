{
  config,
  lib,
  nodes,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.monitoring;
in
{
  options.my.roles.monitoring = {
    enable = lib.mkEnableOption "Monitoring Server";
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = rec {
      enable = true;

      listenAddress = "127.0.0.1";
      port = 9090;
      webExternalUrl = "https://prom.delroth.net/";

      scrapeConfigs =
        let

          baseScrapeConfig = {
            scheme = "https";
            basic_auth = {
              username = "prometheus";
              password = secrets.nodeMetricsKey;
            };
          };

          findExportersFor =
            type:
            let
              hasType = node: node.config.services.prometheus.exporters."${type}".enable;
              exporterNodes = builtins.filter hasType (builtins.attrValues nodes);
            in
            map (n: "${n.config.my.networking.fqdn}:443") exporterNodes;

          blackboxTargets =
            {
              job_name,
              scrape_interval,
              modules,
              targets,
            }:
            let
              exporters = findExportersFor "blackbox";
            in
            baseScrapeConfig
            // {
              job_name = job_name;
              scrape_interval = scrape_interval;
              metrics_path = "/probe/blackbox";
              params = {
                module = modules;
              };
              static_configs =
                map
                  (t: {
                    targets = exporters;
                    labels.target = t;
                  })
                  targets;
              relabel_configs = [
                {
                  source_labels = [ "target" ];
                  target_label = "__param_target";
                }
              ];
            };

          snmpTargets =
            {
              job_name,
              scrape_interval,
              modules,
              targets,
            }:
            let
              exporters = findExportersFor "snmp";
            in
            baseScrapeConfig
            // {
              job_name = job_name;
              scrape_interval = scrape_interval;
              metrics_path = "/snmp/snmp";
              params = {
                module = modules;
              };
              static_configs =
                map
                  (t: {
                    targets = exporters;
                    labels.target = t;
                  })
                  targets;
              relabel_configs = [
                {
                  source_labels = [ "target" ];
                  target_label = "__param_target";
                }
              ];
            };

          whiteboxJob =
            exporterName:
            baseScrapeConfig
            // {
              job_name = exporterName;
              scrape_interval = "10s";
              metrics_path = "/metrics/${exporterName}";
              static_configs =
                let
                  hasExporter = node: node.config.services.prometheus.exporters."${exporterName}".enable;

                  nodesWithExporter = builtins.filter hasExporter (builtins.attrValues nodes);

                  nodeIsRoaming = node: node.config.my.monitoring.roaming;
                  partByRoaming = builtins.partition nodeIsRoaming nodesWithExporter;

                  nodeTarget = node: "${node.config.my.networking.fqdn}:443";
                  roamingTargets = map nodeTarget partByRoaming.right;
                  nonRoamingTargets = map nodeTarget partByRoaming.wrong;
                in
                [
                  {
                    targets = roamingTargets;
                    labels = {
                      roaming = "true";
                    };
                  }
                  {
                    targets = nonRoamingTargets;
                    labels = {
                      roaming = "false";
                    };
                  }
                ];
            };
        in
        [
          (whiteboxJob "apcupsd")
          (whiteboxJob "nginx")
          (whiteboxJob "node")
          (whiteboxJob "rtl_433")

          (blackboxTargets {
            job_name = "http_probe";
            scrape_interval = "1m";
            modules = [ "https_2xx" ];
            targets = [ "https://delroth.net" ];
          })

          (blackboxTargets {
            job_name = "smtp_probe";
            scrape_interval = "1m";
            modules = [ "smtp_starttls" ];
            targets = [ "chaos.delroth.net:25" ];
          })

          (blackboxTargets {
            job_name = "icmp_probe";
            scrape_interval = "1m";
            modules = [ "icmp" ];
            targets = [
              "8.8.8.8"
              "2001:4860:4860::8844"
              "aether.delroth.net"
              "chaos.delroth.net"
              "eden.delroth.net"
            ];
          })

          (snmpTargets {
            job_name = "snmp_homenet";
            scrape_interval = "1m";
            modules = [ "if_mib" ];
            targets = [
              "192.168.1.52" # sw-living-room
            ];
          })

          {
            job_name = "hass";
            scrape_interval = "1m";
            scheme = "https";
            metrics_path = "/api/prometheus";
            bearer_token = secrets.iot.token;
            static_configs = [ { targets = [ "hass.delroth.net:443" ]; } ];
          }
        ];

      alertmanager = {
        enable = true;

        listenAddress = "127.0.0.1";
        port = 9093;
        webExternalUrl = "https://am.delroth.net";

        # AM clustering doesn't like when the machine doesn't have an RFC1918 IP.
        extraFlags = [ "--cluster.listen-address=''" ];

        configuration = {
          global = {
            smtp_smarthost = "127.0.0.1:25";
            smtp_from = "alerts@delroth.net";
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

      alertmanagers = [
        {
          static_configs = [
            { targets = [ "${alertmanager.listenAddress}:${toString alertmanager.port}" ]; }
          ];
        }
      ];

      ruleFiles = [ ./monitoring.rules ];
    };

    services.grafana = {
      enable = true;
      settings = {
        server.domain = "mon.delroth.net";
        server.root_url = "https://mon.delroth.net/";
        security.secret_key = secrets.grafanaSecretKey;
        "auth.proxy".enabled = true;
        "auth.proxy".header_name = "X-User";
      };
    };
  };
}
