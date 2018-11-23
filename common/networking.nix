{ machineName, ... }:

{
  networking.hostName = "${machineName}.delroth.net";
  networking.firewall.allowPing = true;
  networking.nameservers = ["8.8.8.8" "8.8.4.4"];
}
