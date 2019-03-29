{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.laptopBase

    my.roles.gamingClient
    my.roles.infraDevMachine
    my.roles.syncthingMirror
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "lowell";
  };

  my.stateless = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget chromiumBeta xterm most mpv feh pavucontrol acpi git dex gnupg
    cifs-utils tpm2-tools git-crypt python3 pwgen keepassxc vulnix electrum
    lm_sensors xorg.xbacklight picocom whois transmission-remote-cli scrot
    imgurbash2 my.pkgs.vim nixops gnome3.eog evince
  ];

  # TODO: Switch to NetworkManager.
  networking.wireless.networks = my.secrets.wirelessNetworks;

  programs.zsh.enable = true;
  users.users.delroth.shell = pkgs.zsh;

  programs.gnupg.agent.enable = true;
  programs.ssh.startAgent = true;

  hardware.u2f.enable = true;

  boot.kernelModules = [ "cifs" "cmac" "md4" "sha512" ];

  my.roles.gaming-client.enable = true;
  my.roles.infra-dev-machine.enable = true;
  my.roles.syncthing-mirror.enable = true;
}
