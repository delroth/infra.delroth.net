{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.my.roles.homenet-gateway;
in
{
  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    # Enable IPv6 forwarding.
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.default.forwarding" = true;
    };

    networking.interfaces."${cfg.upstreamIface}" = {
      useDHCP = true;
    };

    networking.interfaces."${cfg.downstreamBridge}" = {
      ipv4.addresses = [
        {
          address = "192.168.${toString cfg.mainSubnet}.254";
          prefixLength = 24;
        }
      ];
    };

    networking.vlans.iot = {
      id = cfg.iotSubnet;
      interface = cfg.downstreamBridge;
    };
    networking.interfaces.iot = {
      ipv4.addresses = [
        {
          address = "192.168.${toString cfg.iotSubnet}.254";
          prefixLength = 24;
        }
      ];
    };

    systemd.network.config.routeTables.pub = 99;

    networking.vlans.pub = {
      id = cfg.pubSubnet;
      interface = cfg.downstreamBridge;
    };
    networking.interfaces.pub = {
      ipv4.addresses = [
        {
          address = "192.168.${toString cfg.pubSubnet}.254";
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
  };
}
