{ config, lib, pkgs, secrets, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.laptopBase

    my.roles
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "lowell";
  };

  my.stateless = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget chromium xterm most mpv feh lxqt.pavucontrol-qt acpi gitFull dex gnupg
    cifs-utils tpm2-tools git-crypt python3 pwgen keepassxc vulnix electrum
    lm_sensors xorg.xbacklight picocom whois transmission scrot imgurbash2
    vim_delroth gnome3.eog evince libnotify hexedit blitzloop wireguard-tools
  ];

  # TODO: Switch to NetworkManager.
  networking.wireless.networks = secrets.wirelessNetworks;

  programs.zsh.enable = true;
  users.users.delroth.shell = pkgs.zsh;

  programs.gnupg.agent.enable = true;
  programs.ssh.startAgent = true;

  hardware.u2f.enable = true;

  boot.kernelModules = [
    # For CIFS mounting.
    "cifs" "cmac" "md4" "sha512"

    # FTDI
    "ftdi_sio"

    # USB mass storage
    "usb_storage" "sd_mod" "vfat"

    # TODO: Temporary.
    "wireguard"
  ];

  # TODO: Temporary.
  boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

  my.roles = {
    gaming-client.enable = true;
    infra-dev-machine.enable = true;
    syncthing-mirror.enable = true;
    wireguard-peer.enable = true;
  };
}
