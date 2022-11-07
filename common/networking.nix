{ config, lib, machineName, pkgs, ... }:

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

    fqdn = mkOption {
      type = types.str;
      description = "FQDN of the machine.";
    };
  };

  config = {
    networking.hostName = machineName;
    networking.domain = "delroth.net";
    my.networking.fqdn = "${machineName}.delroth.net";
    networking.search = [ "delroth.net" ];

    networking.firewall.allowPing = true;

    # Default to systemd-networkd usage.
    networking.useNetworkd = lib.mkDefault true;
    systemd.network.wait-online.anyInterface = lib.mkDefault config.networking.useDHCP;

    # Use systemd-resolved for DoT support.
    services.resolved = {
      enable = true;
      dnssec = "false";
      extraConfig = ''
        DNSOverTLS=yes
      '';
    };

    # Used by systemd-resolved, not directly by resolv.conf.
    networking.nameservers = [
      "8.8.8.8#dns.google"
      "1.0.0.1#cloudflare-dns.com"
    ];

    # Too spammy on most servers that get scanned.
    networking.firewall.logRefusedConnections = false;

    # Leaks IPv6 route table entries due to kernel bug. This leads to degraded
    # IPv6 performance in some situations.
    networking.firewall.checkReversePath =
        config.boot.kernelPackages.kernelAtLeast "5.16";

    boot.kernel.sysctl = {
      "net.ipv4.tcp_fastopen" = 3;  # Enable for incoming and outgoing.
      "net.ipv4.tcp_tw_reuse" = 1;
    };

    # Useful networking tools which really ought to be everywhere.
    boot.kernelModules = [ "af_packet" ];
    environment.systemPackages = with pkgs; [ mtr tcpdump traceroute ];
  };
}
