{
  config,
  lib,
  pkgs,
  ...
}:

let
  # https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md
  blackboxConfig = {
    modules = {
      https_2xx = {
        prober = "http";
        timeout = "5s";
        http = {
          method = "GET";
          valid_status_codes = [ ];
          fail_if_not_ssl = true;
        };
      };

      smtp_starttls = {
        prober = "tcp";
        timeout = "5s";
        tcp.query_response = [
          { expect = "^220 ([^ ]+) ESMTP (.+)$"; }
          { send = "EHLO prober"; }
          { expect = "^250-STARTTLS"; }
          { send = "STARTTLS"; }
          { expect = "^220"; }
          { starttls = true; }
          { send = "EHLO prober"; }
          { expect = "^250-AUTH"; }
          { send = "QUIT"; }
        ];
      };

      icmp = {
        prober = "icmp";
        timeout = "5s";
      };
    };
  };
in
{
  options.my.roles.blackbox-prober = {
    enable = lib.mkEnableOption "Blackbox prober";
  };

  config = lib.mkIf config.my.roles.blackbox-prober.enable {
    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9115;
      configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON blackboxConfig);
    };
  };
}
