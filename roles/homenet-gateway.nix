{ config, lib, ... }:

let
  cfg = config.my.roles.homenet-gateway;

  dhcpHosts =
    let
      lines = lib.mapAttrsToList (hostname: info:
        "dhcp-host=${info.mac},${cfg.homenetIp4}${toString info.ip},[::${toString info.ip}],${hostname}"
      ) cfg.homenetExtraHosts;
    in builtins.concatStringsSep "\n" lines;
in {
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

    homenetGatewayIp4 = mkOption {
      type = types.str;
      description = "IPv4 address used as the internal gateway IP.";
    };

    homenetIp4 = mkOption {
      type = types.str;
      description = "IPv4 network used as the internal gateway network.";
      example = "192.168.1.";
    };

    homenetIp4Cidr = mkOption {
      type = types.int;
      description = "CIDR of the IPv4 network used as the internal gateway network.";
    };

    homenetDhcp4Start = mkOption {
      type = types.str;
      description = "First IPv4 that can be allocated as dynamic DHCPv4 address.";
    };

    homenetDhcp4End = mkOption {
      type = types.str;
      description = "Last IPv4 that can be allocated as dynamic DHCPv4 address.";
    };

    homenetExtraHosts = mkOption {
      type = types.attrs;
      description = "Extra hosts to include in the home network configuration for DNS / DHCP.";
      example = {
        host1 = { mac = "11:22:33:44:55:66"; ipSuffix = 42; };
        host2 = { mac = "1a:2a:3a:4a:5a:6a"; ipSuffix = 51; };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Setting useDHCP manually on one interface implicitly disables it on other
    # interfaces, which is the behavior we want..
    networking.interfaces."${cfg.upstreamIface}" = {
      useDHCP = true;
    };

    networking.interfaces."${cfg.downstreamBridge}" = {
      ipv4.addresses = [
        {
          address = cfg.homenetGatewayIp4;
          prefixLength = cfg.homenetIp4Cidr;
        }
      ];
    };

    # Enable DHCPv6 prefix delegation request on the upstream DHCP client, and
    # be more resilient to DHCP failures by keeping our IPv6 and not falling
    # back to link local.
    networking.dhcpcd.extraConfig = ''
      interface ${cfg.upstreamIface}
        persistent
        noipv4ll
        nodelay
        ia_na 1
        ia_pd 2 ${cfg.downstreamBridge}/0
    '';

    networking.nat = {
      enable = true;
      externalInterface = cfg.upstreamIface;
      internalInterfaces = [ cfg.downstreamBridge ];
    };

    # DHCPv4 / DHCPv6
    networking.firewall.allowedUDPPorts = [ 67 547 ];

    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      extraConfig = ''
        port=0  # Disable DNS

        interface=downstream
        bind-interfaces

        dhcp-authoritative
        dhcp-range=set:downstream,${cfg.homenetDhcp4Start},${cfg.homenetDhcp4End},15m
        dhcp-range=set:downstream,::ff00,::ffff,constructor:downstream,slaac,15m

        dhcp-option=tag:downstream,option:router,${cfg.homenetGatewayIp4}

        dhcp-option=option:dns-server,8.8.8.8,8.8.4.4
        dhcp-option=option6:dns-server,2001:4860:4860::8888,2001:4860:4860::8844

        ${dhcpHosts}

        enable-ra
      '';
    };
  };
}
