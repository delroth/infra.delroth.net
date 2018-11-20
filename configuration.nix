{ config, pkgs, ... }:

{
  imports = [
    ./dns.nix
    ./email.nix
    ./hardware-configuration.nix
    ./http.nix
    ./ipfs.nix
    ./monitoring.nix
    ./networking.nix
    ./security.nix
    ./syncthing.nix
    ./tor.nix

    ./services/nginx-sso.nix
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
    wget weechat screen rsync git mailutils openssl binutils ncdu youtube-dl whois

    (import ./pkgs/vim.nix)
  ];

  nix.autoOptimiseStore = true;
  nix.nixPath = [
    "nixpkgs=/home/delroth/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = true;
    nixos.enable = false;
  };

  programs.mosh.enable = true;

  services.openssh.enable = true;

  users.users.delroth = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII3tjB4KYDok3KlWxdBp/yEmqhhmybd+w0VO4xUwLKKV"
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAm1Fp4fengE7aO0SOdvb+3pCYEB71UDEvb8hN+xzGGeSJQ++5nvxXf320WT8+WYJ8ToPA6uLaEkX55cYlILwQYVlnztjqrfS8sOheNj+x8iOkoQESz0SEtmi206k1u3Ul8bAP+Gl3QTXju3RXWy2aq7En4kFfiNoHgFGdZ7hroPDD+KF53ZCrwzEQiRyhVxsrhSyn0+hBl7L6bWJMslcRDS7uwbxeThlxPodu5ARlbTPuE5h2gvLN6vJQ5UIscr5VvV55PQwxa6qKX5Yqtxw+3fiAmJZjyp/RXPK8gABkSmC0Sso9ewpss8BLGmPw8ASXg3WL94BeeipzE/QZHbH2AQ=="
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMj+Uu24FJNa6WSW7OdlIvsRxLxaQ+TZYeKTpD+rh0VF0VwP0CRWlMW/v3PvpblcGoVGpBwjHUyWEqSWNwSr1/s="
    ];
  };

  system.stateVersion = "18.09";
}
