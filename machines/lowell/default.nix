{ config, lib, pkgs, secrets, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.laptop.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget chromium most mpv feh lxqt.pavucontrol-qt acpi gitFull dex gnupg
    cifs-utils tpm2-tools git-crypt python3 pwgen keepassxc vulnix electrum
    lm_sensors picocom whois transmission scrot imgurbash2 vim_delroth
    gnome3.eog evince libnotify hexedit blitzloop wireguard-tools notify-osd
    glome-login-authorize file unzip

    config.boot.kernelPackages.perf
  ];
  security.chromiumSuidSandbox.enable = true;

  # TODO: Switch to NetworkManager.
  networking.wireless.interfaces = [ "wlp4s0" ];
  networking.wireless.networks = secrets.wirelessNetworks;

  programs.zsh.enable = true;
  users.users.delroth.shell = pkgs.zsh;

  programs.gnupg.agent.enable = true;
  programs.ssh.startAgent = true;

  boot.kernelModules = [
    # For CIFS mounting.
    "cifs" "cmac" "hmac" "md4" "md5" "sha256" "sha512"

    # FTDI / Serial
    "ftdi_sio" "pl2303"

    # USB mass storage
    "usb_storage" "sd_mod" "vfat" "mmc_block"

    # USB RJ45 dongle
    "r8152"

    # TODO: Temporary.
    "wireguard"
  ];

  my.roles = {
    gaming-client.enable = true;
    infra-dev-machine.enable = true;
    syncthing-mirror.enable = true;
    wireguard-peer.enable = true;
  };
}
