{ config, lib, pkgs, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.laptopBase
  ];

  _module.args = {
    staging = lib.mkDefault false;
    machineName = lib.mkDefault "lowell";
  };

  my.stateless = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget chromiumBeta xterm most mpv feh pavucontrol acpi git dex gnupg
    cifs-utils tpm2-tools git-crypt python3 pwgen keepassx2 vulnix electrum
    lm_sensors xorg.xbacklight picocom whois transmission-remote-cli scrot
    imgurbash2 my.pkgs.vim nixops
  ];

  # TODO: Switch to NetworkManager.
  networking.wireless.networks = my.secrets.wirelessNetworks;

  programs.zsh.enable = true;
  users.users.delroth.shell = pkgs.zsh;

  programs.gnupg.agent.enable = true;
  programs.ssh.startAgent = true;

  hardware.u2f.enable = true;
}
