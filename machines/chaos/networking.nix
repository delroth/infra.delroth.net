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
  networking.dhcpcd.enable = false;
  networking.interfaces.ens3 = {
    ipv4.addresses = [
      { address = "195.201.9.37"; prefixLength = 26; }
      { address = vpnIn4; prefixLength = 26; }
    ];
    ipv6.addresses = [
      { address = "2a01:4f8:13b:f15::1"; prefixLength = 64; }
      { address = vpnIn6; prefixLength = 64; }
    ];
  };
  networking.defaultGateway = "195.201.9.58";
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "ens3";
    sourceAddress = "2a01:4f8:13b:f15::1";
  };
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
