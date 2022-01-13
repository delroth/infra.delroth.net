{ pkgs, secrets, ... }:
{
  networking.wireguard.interfaces.wg-bgp-transit = {
    listenPort = 51821;
    privateKey = secrets.bgp.tunnel.privkey;
    ips = [ "fd00:2::2/64" ];
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
    ephemeral = true;
    privateNetwork = true;
    interfaces = [ "wg-bgp-transit" ];
    config = {
      networking = {
        hostName = "bgp";
        domain = "delroth.net";
        search = [ "delroth.net" ];

        interfaces.wg-bgp-transit = {
          ipv6.addresses = [
            { address = "fd00:2::2"; prefixLength = 64; }
            { address = "2a0d:d742:40::1"; prefixLength = 44; }
          ];
        };

        firewall.allowPing = true;
      };

      services.bird2.enable = true;
      services.bird2.config = ''
        router id 1.2.3.4;
        debug protocols all;

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
              if net ~ 2a0d:d742:40::/44 then reject; else accept;
            };
          };
        }
      '';

      environment.systemPackages = with pkgs; [
        tcpdump
        wireguard-tools
      ];
    };
  };
}
