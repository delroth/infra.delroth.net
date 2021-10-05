# Container for options related to a machine's homenet information. These
# options are collected by the homenet-gateway to generate DHCP information,
# port redirects, etc.

{ lib, ... }:

{
  options.my.homenet = with lib; {
    enable = mkEnableOption "Homenet configuration";

    macAddress = mkOption {
      type = types.str;
      description = "MAC address of the homenet connected interface.";
    };

    ipSuffix = mkOption {
      type = types.int;
      description = "IP address suffix of this machine within the homenet.";
    };

    ip4PortForward = mkOption {
      type = types.listOf types.port;
      description = "List of ports being forwarded from the router's external IPv4.";
    };
  };
}
