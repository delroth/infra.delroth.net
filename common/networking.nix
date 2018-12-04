{ machineName, ... }:

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
}
