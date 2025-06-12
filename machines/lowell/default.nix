{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  my = import ../..;
in
{
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.laptop.enable = true;
  my.networking.sshPublicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUd6YUtpcUIyRUJHSVJKdFh6NXJFb2lrdEtKazZZdWo4d0YzV2ZVV2J1Rkwgcm9vdEBsb3dlbGwuZGVscm90aC5uZXQK";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    captive-browser
    chromium
    most
    mpv
    feh
    lxqt.pavucontrol-qt
    acpi
    dex
    gnupg
    cifs-utils
    tpm2-tools
    python3
    pwgen
    keepassxc
    vulnix
    electrum
    lm_sensors
    picocom
    whois
    transmission_4
    escrotum
    imgurbash2
    vim_delroth
    eog
    evince
    libnotify
    wireguard-tools
    notify-osd
    glome
    unzip
    edulo

    config.boot.kernelPackages.perf
  ];
  security.chromiumSuidSandbox.enable = true;

  programs.zsh.enable = true;
  users.users.delroth.shell = pkgs.zsh;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-tty;
  programs.ssh.startAgent = true;

  hardware.sane.enable = true;
  users.users.delroth.extraGroups = [ "scanner" ];

  boot.kernelModules = [
    # FTDI / Serial
    "ftdi_sio"
    "pl2303"

    # USB mass storage
    "usb_storage"
    "sd_mod"
    "vfat"
    "exfat"
    "mmc_block"

    # USB RJ45 dongle
    "r8152"

    # Wi-Fi dependency
    "libarc4"
    "ccm"

    # USB audio
    "snd-usb-audio"

    # TODO: Temporary.
    "wireguard"
  ];

  my.roles = {
    gaming-client.enable = true;
    infra-dev-machine.enable = true;
    nas-client = {
      enable = true;
      server = "smol.delroth.net";
    };
    syncthing-mirror.enable = true;
    wireguard-peer.enable = true;
  };

  my.homenet = {
    enable = true;
    macAddress = "4c:03:4f:fc:48:38";
    ipSuffix = 10;
  };
}
