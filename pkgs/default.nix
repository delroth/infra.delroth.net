self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  publibike-locator = super.callPackage ./publibike-locator.nix {};
  vim_delroth = super.callPackage ./vim.nix {};
}
