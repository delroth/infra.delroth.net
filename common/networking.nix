{ lib, machineName, pkgs, ... }:

{
  options.my.networking = with lib; {
    externalInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Name of the network interface that egresses to the internet. Used for
        e.g. NATing internal networks.
      '';
    };

    external4 = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Main external IPv4 address of the machine.";
    };
    external6 = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Main external IPv6 address of the machine.";
    };
  };

  config = {
    networking.hostName = "${machineName}.delroth.net";
    networking.firewall.allowPing = true;
    networking.search = [ "delroth.net" ];

    # DNS to DNS-over-TLS gateway.
    services.stubby = {
      enable = true;
      upstreamServers = ''
        - address_data: 8.8.8.8
          tls_auth_name: "dns.google"
        - address_data: 1.0.0.1
          tls_auth_name: "cloudflare-dns.com"
      '';
    };
    # Require Stubby to be up for network to be considered available. Avoids
    # sequencing problems at boot time.
    systemd.services.stubby.wantedBy = [ "network-online.target" ];

    # Send to local Stubby resolver.
    networking.nameservers = [ "127.0.0.1" ];

    # Too spammy on most servers that get scanned.
    networking.firewall.logRefusedConnections = false;

    boot.kernel.sysctl = {
      "net.ipv4.tcp_fastopen" = 3;  # Enable for incoming and outgoing.
      "net.ipv4.tcp_tw_reuse" = 1;
    };

    # Useful networking tools which really ought to be everywhere.
    boot.kernelModules = [ "af_packet" ];
    environment.systemPackages = with pkgs; [ mtr tcpdump traceroute ];
  };
}
