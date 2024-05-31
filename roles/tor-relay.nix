{
  config,
  lib,
  machineName,
  ...
}:

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
    # sunny
    "75018790F33716C820745B8F7E27D08DAA3E3877"
  ];
in
{
  options.my.roles.tor-relay = {
    enable = lib.mkEnableOption "Tor Relay";
  };

  config = lib.mkIf cfg.enable {
    services.tor = {
      enable = true;
      openFirewall = true;

      relay = {
        enable = true;
        role = "relay";
      };

      settings = {
        ContactInfo = "tor+${machineName}@delroth.net";
        ControlPort = 9051;
        MyFamily = builtins.concatStringsSep "," myFamily;
        Nickname = "${builtins.replaceStrings [ "-" ] [ "" ] machineName}Delroth";
        NumCPUs = 0;
        ORPort = [ { port = 143; } ];

        # TODO: MetricsPort
      };
    };

    systemd.services.tor.serviceConfig.Nice = 5;

    my.homenet.ip4TcpPortForward = [ 143 ];

    # Exclude Tor diff cache from backups since it causes them to fail due to
    # temp files appearing / disappearing.
    my.backup.extraExclude = [ "/var/lib/tor/diff-cache" ];
  };
}
