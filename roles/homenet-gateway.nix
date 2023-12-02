{
  config,
  lib,
  nodes,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.homenet-gateway;

  homenetNodes = lib.mapAttrs (name: node: node.config.my.homenet) (
    lib.flip lib.filterAttrs nodes (
      name: node:
      (lib.hasAttrByPath
        [
          "my"
          "homenet"
        ]
        node.config
      )
      && node.config.my.homenet.enable
    )
  );

  makePortMap =
    mapName:
    lib.flatten (
      lib.mapAttrsToList
        (
          name: node:
          map
            (port: {
              sourcePort = port;
              destination = "${cfg.homenetIp4}${toString node.ipSuffix}";
            })
            node."${mapName}"
        )
        homenetNodes
    );
  tcpPortMap = makePortMap "ip4TcpPortForward";
  udpPortMap = makePortMap "ip4UdpPortForward";

  dhcpHosts =
    let
      homenetHosts =
        lib.mapAttrsToList
          (name: node: {
            inherit name;
            mac = node.macAddress;
            ip = node.ipSuffix;
          })
          homenetNodes;

      extraHosts =
        lib.mapAttrsToList
          (name: info: {
            inherit name;
            mac = info.mac;
            ip = info.ip;
          })
          cfg.homenetExtraHosts;

      lines =
        builtins.map
          (
            info:
            "dhcp-host=${info.mac},${cfg.homenetIp4}${toString info.ip},[::${toString info.ip}],${info.name}"
          )
          (homenetHosts ++ extraHosts);
    in
    builtins.concatStringsSep "\n" lines;

  formatPortsList =
    l:
    let
      strL = builtins.map builtins.toString l;
    in
    builtins.concatStringsSep ", " strL;

  formatPortRangesList =
    l:
    let
      strL = builtins.map (a: "${builtins.toString a.from}-${builtins.toString a.to}") l;
    in
    (if builtins.length l == 0 then "" else ", ") + builtins.concatStringsSep ", " strL;
in
{
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
        host1 = {
          mac = "11:22:33:44:55:66";
          ipSuffix = 42;
        };
        host2 = {
          mac = "1a:2a:3a:4a:5a:6a";
          ipSuffix = 51;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
        {
          address = "192.168.66.254";
          prefixLength = 24;
        }
      ];
    };

    systemd.network.config.routeTables.pub = 99;

    networking.vlans.pub = {
      id = 99;
      interface = cfg.downstreamBridge;
    };
    networking.interfaces.pub = {
      ipv4.addresses = [
        {
          address = "192.168.99.254";
          prefixLength = 24;
        }
      ];
    };

    systemd.network.networks."40-pub".routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          Family = "both";
          IncomingInterface = "pub";
          Table = "pub";
        };
      }
    ];

    systemd.network.netdevs."40-wg-pub" = {
      enable = true;
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg-pub";
      };
      wireguardConfig = {
        PrivateKeyFile = pkgs.writeText "vpn-private-key" secrets.homenet.public-vpn.private-key;
      };
      wireguardPeers = [
        {
          wireguardPeerConfig = {
            PublicKey = secrets.homenet.public-vpn.public-key;
            Endpoint = secrets.homenet.public-vpn.endpoint;
            AllowedIPs = "0.0.0.0/0";
          };
        }
      ];
    };

    systemd.network.networks."40-wg-pub" = {
      enable = true;
      name = "wg-pub";
      networkConfig = {
        Address = "${secrets.homenet.public-vpn.ip}/32";
      };
      routes = [
        {
          routeConfig = {
            Gateway = "0.0.0.0";
            Table = "pub";
          };
        }
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
      networkConfig.IPv6AcceptRA = false;
      networkConfig.IPv6SendRA = true;
      networkConfig.DHCPPrefixDelegation = true;
      dhcpPrefixDelegationConfig.UplinkInterface = "upstream";
      dhcpPrefixDelegationConfig.Token = "::ff";
      ipv6SendRAConfig.Managed = true;
    };

    # We define our own nftables-based firewall ruleset.
    networking.nat.enable = false;
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          set tcp_open_ports {
            typeof tcp dport
            flags interval
            counter
            elements = { ${formatPortsList config.networking.firewall.allowedTCPPorts} ${formatPortRangesList config.networking.firewall.allowedTCPPortRanges} }
          }

          set udp_open_ports {
            typeof udp dport
            flags interval
            counter
            elements = { ${formatPortsList config.networking.firewall.allowedUDPPorts} ${formatPortRangesList config.networking.firewall.allowedUDPPortRanges} }
          }

          flowtable f {
            hook ingress priority filter
            devices = { "${cfg.upstreamIface}", "${cfg.downstreamBridge}", "wg-pub" }
          }

          chain input {
            type filter hook input priority filter
            policy drop

            iif lo accept

            ct state { established, related } counter accept
            tcp dport @tcp_open_ports accept
            udp dport @udp_open_ports accept
            meta l4proto ipv6-icmp accept
            meta l4proto icmp accept
          }

          chain output {
            type filter hook output priority filter
            policy accept
          }

          chain forward {
            type filter hook forward priority filter
            policy drop

            ip6 nexthdr { tcp, udp } flow offload @f;

            iifname . oifname {
              "${cfg.downstreamBridge}" . "${cfg.downstreamBridge}",
              "${cfg.downstreamBridge}" . "${cfg.upstreamIface}",
              "pub" .  "pub",
              "${cfg.downstreamBridge}" . "pub",
              "pub" . "wg-pub"
            } accept

            meta nfproto ipv6 iifname "${cfg.upstreamIface}" oifname "${cfg.downstreamBridge}" accept

            ct status dnat accept
            ct state { established, related } accept
          }
        }

        table ip nat {
          chain port_redirects {
            type nat hook prerouting priority dstnat
            policy accept

            ${
              builtins.concatStringsSep "\n" (
                map
                  (
                    e:
                    ''iifname "${cfg.upstreamIface}" tcp dport ${builtins.toString e.sourcePort} dnat to ${e.destination}''
                  )
                  tcpPortMap
              )
            }

            ${
              builtins.concatStringsSep "\n" (
                map
                  (
                    e:
                    ''ifname "${cfg.upstreamIface}" udp dport ${builtins.toString e.sourcePort} dnat to ${e.destination}''
                  )
                  udpPortMap
              )
            }
          }

          chain nat_masquerade {
            type nat hook postrouting priority srcnat
            policy accept

            iifname "${cfg.downstreamBridge}" oifname "${cfg.upstreamIface}" masquerade
            iifname "pub" oifname "wg-pub" masquerade
          }
        }
      '';

      preCheckRuleset = ''
        sed 's/devices = {.*/devices = { lo };/g' -i ruleset.conf
      '';
    };

    # XXX: https://github.com/NixOS/nixpkgs/issues/141802
    systemd.services.nftables.before = lib.mkForce [];
    systemd.services.nftables.after = ["network-pre.target"];

    # Enable IPv6 forwarding.
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.default.forwarding" = true;
    };

    # DHCPv4 / DHCPv6
    networking.firewall.allowedUDPPorts = [
      67
      546
      547
    ];

    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      extraConfig = ''
        port=0  # Disable DNS

        interface=${cfg.downstreamBridge}
        interface=pub
        bind-interfaces

        dhcp-authoritative
        dhcp-range=set:downstream,${cfg.homenetDhcp4Start},${cfg.homenetDhcp4End},15m
        dhcp-range=set:downstream,::ff00,::ffff,constructor:downstream,slaac,15m

        dhcp-option=tag:downstream,option:router,${cfg.homenetGatewayIp4}

        dhcp-range=pub,192.168.99.50,192.168.99.100,15m
        dhcp-option=pub,option:router,192.168.99.254

        dhcp-option=option:dns-server,8.8.8.8,8.8.4.4
        dhcp-option=option6:dns-server,2001:4860:4860::8888,2001:4860:4860::8844

        ${dhcpHosts}

        enable-ra
      '';
    };
  };
}
