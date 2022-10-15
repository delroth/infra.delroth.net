{ config, lib, nodes, ... }:

let
  cfg = config.my.roles.homenet-gateway;

  homenetNodes =
    lib.mapAttrs (name: node: node.config.my.homenet) (
      lib.flip lib.filterAttrs nodes (name: node:
        (lib.hasAttrByPath [ "my" "homenet" ] node.config) &&
        node.config.my.homenet.enable
      )
    );

  portMaps = let
    makePortMap = proto: mapName: lib.flatten (
      lib.mapAttrsToList (name: node:
        map (port: {
          inherit proto;
          sourcePort = port;
          destination = "${cfg.homenetIp4}${toString node.ipSuffix}";
        }) node."${mapName}"
      ) homenetNodes
    );
  in
    (makePortMap "tcp" "ip4TcpPortForward") ++ (makePortMap "udp" "ip4UdpPortForward");

  dhcpHosts =
    let
      homenetHosts = lib.mapAttrsToList (name: node: {
        inherit name;
        mac = node.macAddress;
        ip = node.ipSuffix;
      }) homenetNodes;

      extraHosts = lib.mapAttrsToList (name: info: {
        inherit name;
        mac = info.mac;
        ip = info.ip;
      }) cfg.homenetExtraHosts;

      lines = builtins.map (info:
        "dhcp-host=${info.mac},${cfg.homenetIp4}${toString info.ip},[::${toString info.ip}],${info.name}"
      ) (homenetHosts ++ extraHosts);
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
    networking.useNetworkd = true;
    networking.useDHCP = false;

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

    networking.vlans.iot = {
      id = 66;
      interface = cfg.downstreamBridge;
    };
    networking.interfaces.iot = {
      ipv4.addresses = [
        { address = "192.168.66.254"; prefixLength = 24; }
      ];
    };

    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    # TODO: Expose this as a proper nixos option later down the line.
    systemd.network.networks."40-${cfg.upstreamIface}" = {
      networkConfig.KeepConfiguration = "dhcp";
      dhcpV6Config.PrefixDelegationHint = "::/48";
      # XXX: This should not be needed, but for some reason part of networkd
      # isn't seeing the RAs and not triggering DHCPv6. Even though some other
      # part of networkd is properly seeing them and logging accordingly.
      dhcpV6Config.WithoutRA = "solicit";
    };
    systemd.network.networks."40-${cfg.downstreamBridge}" = {
      networkConfig.IPv6SendRA = true;
      networkConfig.DHCPPrefixDelegation = true;
      dhcpPrefixDelegationConfig.UplinkInterface = "upstream";
      dhcpPrefixDelegationConfig.Token = "::ff";
      ipv6SendRAConfig.Managed = true;
    };

    networking.nat = {
      enable = true;
      externalInterface = cfg.upstreamIface;
      internalInterfaces = [
        cfg.downstreamBridge
        "iot@downstream"
      ];
      forwardPorts = portMaps;
    };

    # Enable IPv6 forwarding.
    boot.kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.default.forwarding" = true;
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
