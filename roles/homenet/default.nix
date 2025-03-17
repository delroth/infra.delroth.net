{
  config,
  lib,
  ...
}:
{
  imports = [
    ./dhcp.nix
    ./firewall.nix
    ./ifaces.nix
    ./igmp.nix
    ./mdns.nix
    ./sniproxy.nix
  ];

  options.my.roles.homenet-gateway = with lib; {
    enable = mkEnableOption "Home Network Gateway";

    upstreamIface = mkOption {
      type = types.str;
      description = "Interface used as the upstream network for the gateway.";
    };

    downstreamBridge = mkOption {
      type = types.str;
      description = "Interface (usually a bridge) used as the downstream network for the gateway.";
    };

    homenetIp6Prefix = mkOption {
      type = types.str;
      description = "IPv6 prefix allocated to the home network.";
      example = "2000:1234:5678:";
    };

    homenetIp6Cidr = mkOption {
      type = types.int;
      description = "CIDR of the IPv6 prefix allocated to the home network.";
    };

    mainSubnet = mkOption {
      type = types.int;
      description = "Subnet id of the main privileged subnet.";
    };

    iotSubnet = mkOption {
      type = types.int;
      description = "Subnet id of the IoT subnet.";
    };

    pubSubnet = mkOption {
      type = types.int;
      description = "Subnet id of the public subnet.";
    };
  };
}
