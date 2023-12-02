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
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/0caff5465662870282e8637b68ad52189a40933d/snmp.yml";
    sha256 = "sha256-JRUEsFJQZB1XNohf4YR7WxGRRoTvFw0V7YO/jp9y3P4=";
  };
  snmpConfig = pkgs.runCommand "snmp-config" {} ''
    ${pkgs.yq-go}/bin/yq eval \
      '. * {"if_mib": {"auth": { "community": "${communityString}" }}}' \
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
