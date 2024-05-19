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

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    chromium
    most
    mpv
    feh
    lxqt.pavucontrol-qt
    acpi
    gitFull
    dex
    gnupg
    cifs-utils
    tpm2-tools
    git-crypt
    python3
    pwgen
    keepassxc
    vulnix
    electrum
    lm_sensors
    picocom
    whois
    transmission
    escrotum
    imgurbash2
    vim_delroth
    gnome.eog
    evince
    libnotify
    hexedit
    wireguard-tools
    notify-osd
    glome
    file
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
