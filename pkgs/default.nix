self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  chiaki = super.libsForQt5.callPackage ./chiaki.nix {};
  vim_delroth = super.callPackage ./vim.nix {};
}
