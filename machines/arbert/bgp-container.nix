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
          ipv6.addresses = [ { address = "fd00:2::2"; prefixLength = 64; } ];
        };

        firewall.allowPing = true;
      };

      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];
    };
  };
}
