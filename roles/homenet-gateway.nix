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

  dhcp4Reservations =
    builtins.map
      (
        info: {
          hw-address = info.mac;
          ip-address = "${cfg.homenetIp4}${toString info.ip}";
          hostname = info.name;
        }
      )
      (homenetHosts ++ extraHosts);

  dhcp6Reservations =
    builtins.map
      (
        info: {
          hw-address = info.mac;
          ip-addresses = [ "${cfg.homenetIp6Prefix}0::${toString info.ip}" ];
          hostname = info.name;
        }
      )
      (homenetHosts ++ extraHosts);

  formatPortsList =
    l:
    let
      strL = builtins.map toString l;
    in
    builtins.concatStringsSep ", " strL;

  formatPortRangesList =
    l:
    let
      strL = builtins.map (a: "${toString a.from}-${toString a.to}") l;
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

    homenetIp6Prefix = mkOption {
      type = types.str;
      description = "IPv6 prefix allocated to the home network.";
      example = "2000:1234:5678:";
    };

    homenetIp6Cidr = mkOption {
      type = types.int;
      description = "CIDR of the IPv6 prefix allocated to the home network.";
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
        Family = "both";
        IncomingInterface = "pub";
        Table = "pub";
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
          PublicKey = secrets.homenet.public-vpn.public-key;
          Endpoint = secrets.homenet.public-vpn.endpoint;
          AllowedIPs = "0.0.0.0/0";
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
          Gateway = "0.0.0.0";
          Table = "pub";
        }
      ] ++ (map (n: {
        Gateway = "0.0.0.0";
        Destination = n;
      }) secrets.homenet.vpnRoutedNets);
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

    # Enable IGMP proxying. Note that default NixOS kernels do not enable
    # CONFIG_IP_MROUTE by default.
    #
    # TODO: actual IGMP proxying.
    boot.kernelPatches = [{
      name = "enable_ip_mroute";
      patch = null;
      extraStructuredConfig = {
        IP_MROUTE = lib.kernel.yes;
      };
    }];

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

            # Only expose Avahi on internal interfaces that need mDNS bridging.
            iifname { "${cfg.downstreamBridge}", "iot" } udp dport 5353 accept
          }

          chain output {
            type filter hook output priority filter
            policy accept
          }

          chain forward {
            type filter hook forward priority filter
            policy drop

            ip protocol { tcp, udp } flow offload @f;

            # Never try to forward link-local traffic. It is bound to fail. I'm
            # not sure why Linux even tries to allow this.
            #
            # https://mastodon.delroth.net/@delroth/114161473282235619
            ip saddr 169.254.0.0/16 drop
            ip daddr 169.254.0.0/16 drop

            iifname . oifname {
              "${cfg.downstreamBridge}" . "${cfg.downstreamBridge}",
              "${cfg.downstreamBridge}" . "${cfg.upstreamIface}",
              "${cfg.downstreamBridge}" . "wg-pub",
              "${cfg.downstreamBridge}" . "pub",
              "pub" .  "pub",
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
                    ''iifname "${cfg.upstreamIface}" tcp dport ${toString e.sourcePort} dnat to ${e.destination}''
                  )
                  tcpPortMap
              )
            }

            ${
              builtins.concatStringsSep "\n" (
                map
                  (
                    e:
                    ''ifname "${cfg.upstreamIface}" udp dport ${toString e.sourcePort} dnat to ${e.destination}''
                  )
                  udpPortMap
              )
            }
          }

          chain nat_masquerade {
            type nat hook postrouting priority srcnat
            policy accept

            iifname "${cfg.downstreamBridge}" oifname "${cfg.upstreamIface}" masquerade
            iifname "${cfg.downstreamBridge}" oifname "wg-pub" masquerade
            iifname "pub" oifname "wg-pub" masquerade
          }
        }
      '';

      preCheckRuleset = ''
        sed 's/devices = {.*/devices = { lo };/g' -i ruleset.conf
      '';
    };

    # XXX: https://github.com/NixOS/nixpkgs/issues/141802
    systemd.services.nftables.before = lib.mkForce [ ];
    systemd.services.nftables.after = [ "network-pre.target" ];

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

    services.kea = {
      dhcp4 = {
        enable = true;
        settings = {
          interfaces-config.interfaces = [ cfg.downstreamBridge "iot" "pub" ];

          lease-database = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp4.leases";
          };

          option-data = [
            { name = "domain-name-servers"; data = "8.8.8.8, 8.8.4.4"; }
          ];

          subnet4 = [
            # Main subnet.
            {
              id = 1;
              interface = cfg.downstreamBridge;
              subnet = "${cfg.homenetGatewayIp4}/${toString cfg.homenetIp4Cidr}";
              pools = [ { pool = "${cfg.homenetDhcp4Start} - ${cfg.homenetDhcp4End}"; } ];
              reservations = dhcp4Reservations;
              option-data = [ { name = "routers"; data = cfg.homenetGatewayIp4; } ];
            }

            # IoT subnet.
            {
              id = 66;
              interface = "iot";
              subnet = "192.168.66.0/24";
              pools = [ { pool = "192.168.66.50 - 192.168.66.200"; } ];
              option-data = [ { name = "routers"; data = "192.168.66.254"; } ];
            }

            # Public subnet.
            {
              id = 99;
              interface = "pub";
              subnet = "192.168.99.0/24";
              pools = [ { pool = "192.168.99.50 - 192.168.99.200"; } ];
              option-data = [ { name = "routers"; data = "192.168.99.254"; } ];
            }
          ];
        };
      };

      dhcp6 = {
        enable = true;
        settings = {
          interfaces-config.interfaces = [ cfg.downstreamBridge "iot" "pub" ];

          lease-database = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp6.leases";
          };

          option-data = [
            { name = "dns-servers"; data = "2001:4860:4860::8888, 2001:4860:4860::8844"; }
          ];

          subnet6 = [
            # Main subnet.
            {
              id = 1;
              interface = cfg.downstreamBridge;
              subnet = "${cfg.homenetIp6Prefix}0::/64";
              pools = [ { pool = "${cfg.homenetIp6Prefix}0::ff00 - ${cfg.homenetIp6Prefix}0::ffff"; }];
              reservations = dhcp6Reservations;
            }

            # TODO: Public and IoT networks.
          ];
        };
      };
    };
  };
}
