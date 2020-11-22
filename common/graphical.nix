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

    # Patch mpv to avoid TrueHD buffering issues on CIFS.
    nixpkgs.overlays = [(self: super: {
      mpv-unwrapped = super.mpv-unwrapped.overrideAttrs (old: {
        patches = old.patches ++ [
          (self.fetchpatch {
            url = "https://github.com/mpv-player/mpv/commit/c59ca06a0fff432ac4cae012bb0299a8db9a00d3.patch";
            sha256 = "0iq9bafylmj129pb8v6p8gxmjaw8nisiixfxc0ri2bhv905wqc45";
          })
          (self.fetchpatch {
            url = "https://github.com/mpv-player/mpv/commit/20eead18130fd460d8e9eff50ce14afd3646faab.patch";
            sha256 = "16w77nvnq1awkkdnzd3nk2n2n4s22xmcz04d62jcpjq70r244xfd";
          })
        ];
      });
    })];
  };
}
