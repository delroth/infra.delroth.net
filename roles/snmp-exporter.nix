{
  config,
  lib,
  pkgs,
  ...
}:

let
  # QNAP is annoying and uses "PUBLIC" instead of "public" as default community
  # string. That means we need to go and patch the default SNMP exporter
  # configuration.
  communityString = "PUBLIC";
  defaultSnmpConfig = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/1242b20f9e2050f4d3011818ad3cd0f9d195b78e/snmp.yml";
    sha256 = "sha256-4mfQYSmLH/WAw4M30XZt4P6AkWEIYoN8VU6Hz958yUc=";
  };
  snmpConfig = pkgs.runCommand "snmp-config" { } ''
    ${pkgs.yq-go}/bin/yq eval \
      '. * {"auths": {"public_v2": { "community": "${communityString}" }}}' \
      ${defaultSnmpConfig} > $out
  '';
in
{
  options.my.roles.snmp-exporter = {
    enable = lib.mkEnableOption "SNMP exporter";
  };

  config = lib.mkIf config.my.roles.snmp-exporter.enable {
    services.prometheus.exporters.snmp = {
      enable = true;
      port = 9116;
      configurationPath = snmpConfig;
    };
  };
}
