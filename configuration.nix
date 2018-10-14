{ config, pkgs, ... }:

{
  imports = [
    ./dns.nix
    ./email.nix
    ./hardware-configuration.nix
    ./http.nix
    ./monitoring.nix
    ./networking.nix
    ./security.nix
    ./tor.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  i18n = {
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Zurich";

  environment.systemPackages = with pkgs; [
    wget vim weechat screen rsync git mailutils openssl
  ];

  programs.mosh.enable = true;

  services.openssh.enable = true;

  users.users.delroth = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII3tjB4KYDok3KlWxdBp/yEmqhhmybd+w0VO4xUwLKKV"];
  };

  system.stateVersion = "18.09";
}
