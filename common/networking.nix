{ machineName, pkgs, ... }:

{
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
  # sequencing problems at boot time. This requires custom patching in order to
  # use a Type=notify service.
  nixpkgs.overlays = [(self: super: {
    stubby = super.stubby.overrideAttrs (old: {
      patches = [
        (pkgs.fetchurl {
          url = "https://github.com/delroth/stubby/commit/6f1b64e1da657e8c9befb99498e64e66a7821b9f.patch";
          sha256 = "0icc1f3xlc7lx8vjy560cgm2b81y20d1lv5anrfriirvp6dd8dh1";
        })
      ];
      buildInputs = old.buildInputs ++ [ pkgs.systemd ];
    });
  })];
  systemd.services.stubby.serviceConfig.Type = "notify";
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
}
