self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  parsec = super.callPackage ./parsec.nix {};
  publibike-locator = super.callPackage ./publibike-locator.nix {};
  vim_delroth = super.callPackage ./vim.nix {};
}
