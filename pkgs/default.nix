self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  glome = super.callPackage ./glome.nix {};
  parsec = super.callPackage ./parsec.nix {};
  publibike-locator = super.callPackage ./publibike-locator.nix {};
  repology-notifier = super.callPackage ./repology-notifier.nix {};
  vim_delroth = super.callPackage ./vim.nix {};
}
