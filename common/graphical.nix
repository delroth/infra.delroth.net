{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.my.laptop.enable {
    boot.plymouth.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
    };

    fonts = {
      enableDefaultFonts = true;
      fonts = with pkgs; [
        google-fonts liberation_ttf open-sans roboto roboto-mono
        kochi-substitute
      ];
    };

    services.xserver = {
      enable = true;

      layout = "ca";
      xkbVariant = "multix";
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
