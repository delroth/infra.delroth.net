{
  config,
  lib,
  nodes,
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
      secrets.homenet.extraHosts;

  dhcp4ReservationsForNet = net:
    builtins.map
      (
        info: {
          hw-address = info.mac;
          ip-address = "192.168.${net}.${info.ip}";
          hostname = info.name;
        }
      )
      (homenetHosts ++ extraHosts);

  dhcp6Reservations =
    builtins.map
      (
        info: {
          hw-address = info.mac;
          ip-addresses = [ "${cfg.homenetIp6Prefix}0::${info.ip}" ];
          hostname = info.name;
        }
      )
      (homenetHosts ++ extraHosts);
in
{
  config = lib.mkIf cfg.enable {
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
              id = cfg.mainSubnet;
              interface = cfg.downstreamBridge;
              subnet = "192.168.${cfg.mainSubnet}.0/24";
              pools = [ { pool = "192.168.${cfg.mainSubnet}.100 - 192.168.${cfg.mainSubnet}.200"; } ];
              reservations = dhcp4ReservationsForNet cfg.mainSubnet;
              option-data = [ { name = "routers"; data = "192.168.${cfg.mainSubnet}.254"; } ];
            }

            # IoT subnet.
            {
              id = cfg.iotSubnet;
              interface = "iot";
              subnet = "192.168.${cfg.iotSubnet}.0/24";
              pools = [ { pool = "192.168.${cfg.iotSubnet}.100 - 192.168.${cfg.iotSubnet}.200"; } ];
              reservations = dhcp4ReservationsForNet cfg.iotSubnet;
              option-data = [ { name = "routers"; data = "192.168.${cfg.iotSubnet}.254"; } ];
            }

            # Public subnet.
            {
              id = cfg.pubSubnet;
              interface = "pub";
              subnet = "192.168.${cfg.pubSubnet}.0/24";
              pools = [ { pool = "192.168.${cfg.pubSubnet}.100 - 192.168.${cfg.pubSubnet}.200"; } ];
              reservations = dhcp4ReservationsForNet cfg.pubSubnet;
              option-data = [ { name = "routers"; data = "192.168.${cfg.pubSubnet}.254"; } ];
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
              id = cfg.mainSubnet;
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
