{ config, lib, machineName, ... }:

let
  cfg = config.my.roles.tor-relay;

  # TODO(delroth): Figure out how to automate this. This will likely
  # require managing keys through infra.delroth.net.
  myFamily = [
    # arbert
    "0432BEE829FCB155CE92CF418B7280F9849E12D0"
    # chaos
    "DD0C8EEC5CA402A9FA4478F10C31A440F71F6885"
    # eden
    "207AB36233C684A88C549ACF766A8D268CB4F796"
    # yew
    "475B34D76756910C11EB7752EB8285F6BE00C1EE"
  ];
in {
  options.my.roles.tor-relay = {
    enable = lib.mkEnableOption "Tor Relay";
  };

  config = lib.mkIf cfg.enable {
    services.tor = {
      enable = true;
      controlPort = 9051;
      relay = {
        enable = true;
        role = "relay";
        port = 143;
        nickname = "${builtins.replaceStrings [ "-" ] [ "" ] machineName}Delroth";
        contactInfo = "tor+${machineName}@delroth.net";
      };

      extraConfig = ''
        MyFamily ${builtins.concatStringsSep "," myFamily}

        # Allow the use of multiple cores (default: 1). We run at higher
        # niceness anyway.
        NumCPUs 0
      '' + (lib.optionalString (config.my.networking.external6 != null) ''
        ORPort [${config.my.networking.external6}]:${builtins.toString config.services.tor.relay.port}
      '');
    };

    systemd.services.tor.serviceConfig.Nice = 5;

    networking.firewall.allowedTCPPorts = [config.services.tor.relay.port];

    # Monitoring.
    services.prometheus.exporters.tor = {
      enable = true;
      torControlPort = config.services.tor.controlPort;
      listenAddress = "127.0.0.1";
      port = 9130;
    };

    # Exclude Tor diff cache from backups since it causes them to fail due to
    # temp files appearing / disappearing.
    my.backup.extraExclude = [ "/var/lib/tor/diff-cache" ];
  };
}
