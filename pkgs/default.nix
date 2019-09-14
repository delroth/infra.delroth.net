self: super: {
  blitzloop = super.callPackage ./blitzloop.nix {};
  vim_delroth = super.callPackage ./vim.nix {};
}
