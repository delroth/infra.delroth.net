{
  config,
  lib,
  pkgs,
  ...
}:

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
      enableDefaultPackages = true;
      packages = with pkgs; [
        google-fonts
        liberation_ttf
        open-sans
        roboto
        roboto-mono
        kochi-substitute
      ];
    };

    programs.sway.enable = true;
    programs.sway.wrapperFeatures.gtk = true;

    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    services.libinput.enable = true;

    i18n.inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    environment.systemPackages = with pkgs; [ alacritty tofi ];
    environment.sessionVariables.TERMINAL = "alacritty";
  };
}
