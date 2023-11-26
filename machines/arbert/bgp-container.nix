{
  pkgs,
  secrets,
  nodes,
  ...
}:
{
  networking.wireguard.interfaces.wg-bgp-transit = {
    listenPort = 51821;
    privateKey = secrets.bgp.tunnel.privkey;
    ips = [ "fd00:2::2/64" ];
    allowedIPsAsRoutes = false;
    peers = [
      {
        name = "bgp-transit";
        endpoint = secrets.bgp.tunnel.endpoint;
        publicKey = secrets.bgp.tunnel.pubkey;
        allowedIPs = [ "::/0" ];
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 51821 ];

  containers.bgp = {
    autoStart = true;
    privateNetwork = true;
    interfaces = [ "wg-bgp-transit" ];
    config = {
      networking = {
        hostName = "bgp";
        useHostResolvConf = false;
        useNetworkd = true;

        nameservers = [ "2001:4860:4860::8844" ];
        domain = "delroth.net";
        search = [ "delroth.net" ];

        interfaces.wg-bgp-transit = {
          ipv6.addresses = [
            {
              address = "fd00:2::2";
              prefixLength = 64;
            }
          ];
        };

        interfaces.lo = {
          ipv6.addresses = [
            {
              address = "2a0d:d742:40::1";
              prefixLength = 44;
            }
          ];
        };

        firewall = {
          allowPing = true;
          logRefusedConnections = false;
          allowedTCPPorts = [ 179 ];
        };
      };

      services.bird2.enable = true;
      services.bird2.config = ''
        router id 1.2.3.4;

        protocol device {
          scan time 10;
        }

        protocol static {
          route 2a0d:d742:40::/44 reject;
          ipv6 {
            import all;
            export none;
          };
        }

        protocol kernel {
          scan time 20;
          ipv6 {
            import none;
            export filter {
              if source = RTS_STATIC then reject;
              krt_prefsrc = 2a0d:d742:40::1;
              accept;
            };
          };
        }

        protocol bgp {
          local as 210400;
          neighbor fd00:2::1 as 210036;
          path metric 1;

          ipv6 {
            export filter {
              if source = RTS_STATIC then accept; else reject;
            };
            import filter {
              if net ~ 2a0d:d742:40::/44 then reject;
              if net ~ fd00:2::/64 then reject;
              accept;
            };
          };
        }
      '';

      services.tor = {
        enable = true;
        openFirewall = true;

        relay = {
          enable = true;
          role = "relay";
        };

        settings = {
          ContactInfo = "tor+delrothnet@delroth.net";
          ControlPort = 9051;

          # XXX: kind of a hack, but meh.
          MyFamily = nodes."arbert.delroth.net".config.services.tor.settings.MyFamily;
          Nickname = "arbertDelrothNet";
          NumCPUs = 1;
          ORPort = [
            # This one is just to make Tor happy, we're not actually reachable
            # over IPv4.
            {
              addr = "0.0.0.0";
              port = 143;
            }
            {
              addr = "[2a0d:d742:40::1]";
              port = 143;
            }
          ];

          # Don't abuse the fair use transit too much.
          AccountingStart = "day 0:00";
          AccountingMax = "100 GBytes";
          RelayBandwidthRate = "1 MBytes";
          RelayBandwidthBurst = "10 MBytes";
        };
      };

      environment.systemPackages = with pkgs; [
        tcpdump
        wireguard-tools
      ];
    };
  };

  # Add some dependencies on the VPN tunnel being properly configured before
  # stealing the network interface from the host.
  systemd.services."container@bgp".after = [ "wireguard-wg-bgp-transit.service" ];
  systemd.services."container@bgp".bindsTo = [ "wireguard-wg-bgp-transit.service" ];
}
