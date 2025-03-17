{
  config,
  lib,
  ...
}:
let
  cfg = config.my.roles.homenet-gateway;
in
{
  config = lib.mkIf cfg.enable {
    # Run Avahi in reflector mode to bridge mDNS between main and IOT internal
    # networks.
    services.avahi = {
      enable = true;
      allowInterfaces = [ cfg.downstreamBridge "iot" ];
      openFirewall = false;
      ipv4 = true;
      ipv6 = false;
      reflector = true;
    };
  };
}
