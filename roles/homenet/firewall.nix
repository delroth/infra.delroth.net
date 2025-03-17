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

  makePortMap =
    mapName:
    lib.flatten (
      lib.mapAttrsToList
        (
          name: node:
          map
            (port: {
              sourcePort = port;
              destination = "192.168.${toString cfg.mainSubnet}.${toString node.ipSuffix}";
            })
            node."${mapName}"
        )
        homenetNodes
    );
  tcpPortMap = makePortMap "ip4TcpPortForward";
  udpPortMap = makePortMap "ip4UdpPortForward";

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
  config = lib.mkIf cfg.enable {
    # XXX: https://github.com/NixOS/nixpkgs/issues/141802
    systemd.services.nftables.before = lib.mkForce [ ];
    systemd.services.nftables.after = [ "network-pre.target" ];

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
              "${cfg.downstreamBridge}" . "iot",
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

            # SNI Proxy redirects.
            iifname != "lo" tcp dport 443 fib daddr type local dnat to 127.0.0.1:4443
            iifname != "lo" udp dport 443 fib daddr type local dnat to 127.0.0.1:4443

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

            # Standard v4 NAT.
            iifname "${cfg.downstreamBridge}" oifname "${cfg.upstreamIface}" masquerade
            iifname "${cfg.downstreamBridge}" oifname "wg-pub" masquerade
            iifname "pub" oifname "wg-pub" masquerade

            # Also NAT from homenet to IoT to 1. mask internal devices; 2.
            # allow control of devices that check source IP.
            iifname "${cfg.downstreamBridge}" oifname "iot" masquerade
          }
        }
      '';

      preCheckRuleset = ''
        sed 's/devices = {.*/devices = { lo };/g' -i ruleset.conf
      '';
    };
  };
}
