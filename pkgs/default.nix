self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  glome = super.callPackage ./glome.nix {};
  glome-login-authorize = super.callPackage ./glome-login-authorize.nix {};
  publibike-locator = super.callPackage ./publibike-locator.nix {};
  repology-notifier = super.callPackage ./repology-notifier.nix {};
  vim_delroth = super.callPackage ./vim.nix {};

  # https://nixos.wiki/wiki/Overlays#Python_Packages_Overlay
  python3 = super.python3.override {
    packageOverrides = self: super: {
      pyglome = self.callPackage ./pyglome.nix {};
    };
  };
  python3Packages = self.python3.pkgs;
}
