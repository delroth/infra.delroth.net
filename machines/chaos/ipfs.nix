{ config, pkgs, ... }:

{
  services.ipfs.enable = true;
  services.ipfs.dataDir = "/srv/ipfs";
  services.ipfs.autoMount = true;
  services.ipfs.localDiscovery = false;

  environment.systemPackages = [ pkgs.fuse ];
  boot.kernelModules = [ "fuse "];
  networking.firewall.allowedTCPPorts = [ 4001 ];
}
