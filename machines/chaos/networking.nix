{ lib, secrets, ... }:

let
  vpnIn4 = "195.201.9.57";
  vpnIn6 = "2a01:4f8:13b:f15::2";

  wgcfg = secrets.wireguard.cfg;

  lowellPeer = secrets.wireguard.peers.lowell.clientNum;
  lowellVpn4 = "${wgcfg.subnet4}.${toString lowellPeer}";
  lowellVpn6 = "${wgcfg.subnet6}::${toString lowellPeer}";

  chaosPeer = secrets.wireguard.peers.chaos.clientNum;
  chaosVpn4 = "${wgcfg.subnet4}.${toString chaosPeer}";
  chaosVpn6 = "${wgcfg.subnet6}::${toString chaosPeer}";
in {
  networking.useDHCP = false;
  networking.interfaces.ens3 = {
    ipv4.addresses = [
      { address = "195.201.9.37"; prefixLength = 26; }
      { address = vpnIn4; prefixLength = 26; }
    ];
    ipv4.routes = [
      {
        address = "0.0.0.0";
        prefixLength = 0;
        via = "195.201.9.58";
        options.src = "195.201.9.37";
        options.onlink = true;
      }
    ];

    ipv6.addresses = [
      { address = "2a01:4f8:13b:f15::1"; prefixLength = 64; }
      { address = vpnIn6; prefixLength = 64; }
    ];
    ipv6.routes = [
      {
        address = "::";
        prefixLength = 0;
        via = "fe80::1";
        options.src = "2a01:4f8:13b:f15::1";
        options.onlink = true;
      }
    ];
  };

  # XXX: Disable RAs on the interface.
  systemd.network.networks."40-ens3".networkConfig.IPv6AcceptRA = false;

  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

  my.networking.externalInterface = "ens3";

  # Routing configuration for vpn-in to lowell.
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  boot.kernel.sysctl."net.ipv6.conf.default.forwarding" = true;
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING  -d ${vpnIn4} -j DNAT --to-dest ${lowellVpn4}
    iptables -t nat -A OUTPUT  -d ${vpnIn4} -j DNAT --to-dest ${lowellVpn4}
    ip6tables -t nat -A PREROUTING -d ${vpnIn6} -j DNAT --to-dest ${lowellVpn6}
    ip6tables -t nat -A OUTPUT -d ${vpnIn6} -j DNAT --to-dest ${lowellVpn6}

    iptables -t nat -A POSTROUTING -d ${lowellVpn4} -j SNAT --to-source ${chaosVpn4}
    ip6tables -t nat -A POSTROUTING -d ${lowellVpn6} -j SNAT --to-source ${chaosVpn6}
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -F PREROUTING
    iptables -t nat -F OUTPUT
    iptables -t nat -F POSTROUTING

    ip6tables -t nat -F PREROUTING
    ip6tables -t nat -F OUTPUT
    ip6tables -t nat -F POSTROUTING
  '';
}
