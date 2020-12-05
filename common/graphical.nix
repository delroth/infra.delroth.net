{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.my.laptop.enable {
    boot.plymouth.enable = true;

    sound.enable = true;
    hardware.pulseaudio.enable = true;

    fonts = {
      enableDefaultFonts = true;
      fonts = with pkgs; [
        google-fonts liberation_ttf opensans-ttf roboto roboto-mono
        kochi-substitute
      ];
    };

    services.xserver = {
      enable = true;

      layout = "ca";
      xkbVariant = "multi";
      xkbOptions = "caps:escape";
      libinput.enable = true;

      displayManager.sddm.enable = true;
      windowManager.i3.enable = true;
    };

    i18n.inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };

    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [ vaapiIntel vaapiVdpau libvdpau-va-gl ];
    };

    environment.systemPackages = with pkgs; [ alacritty ];
    environment.sessionVariables.TERMINAL = "alacritty";
  };
}
