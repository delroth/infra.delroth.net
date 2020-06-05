{ pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
  };

  # Remove a few non-essentials to avoid having to build LLVM and Spidermonkey.
  security.apparmor.enable = false;
  security.polkit.enable = false;
  services.udisks2.enable = false;

  # ZFS configuration.
  boot.supportedFilesystems = [ "zfs" ];
  fileSystems."/data" = {
    device = "ds/data";
    fsType = "zfs";
  };
  services.zfs.autoScrub.enable = true;
  environment.systemPackages = with pkgs; [ fio ];

  # SMART monitoring.
  services.smartd = {
    enable = true;
    notifications = {
      mail.enable = true;
      test = true;
    };
  };
}
