{ machineName, pkgs, ... }:

{
  networking.hostName = "${machineName}.delroth.net";
  networking.firewall.allowPing = true;
  networking.search = [ "delroth.net" ];

  # DNS to DNS-over-TLS gateway.
  services.stubby = {
    enable = true;
    upstreamServers = ''
      - address_data: 1.1.1.1
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 1.0.0.1
        tls_auth_name: "cloudflare-dns.com"
    '';
  };

  # Send to local Stubby resolver.
  networking.nameservers = [ "127.0.0.1" ];

  boot.kernel.sysctl = {
    "net.ipv4.tcp_fastopen" = 3;  # Enable for incoming and outgoing.
    "net.ipv4.tcp_tw_reuse" = 1;
  };

  # Useful networking tools which really ought to be everywhere.
  boot.kernelModules = [ "af_packet" ];
  environment.systemPackages = with pkgs; [ mtr tcpdump traceroute ];
}
