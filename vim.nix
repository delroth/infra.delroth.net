with import <nixpkgs> {};

vim_configurable.customize {
  name = "vim";
  vimrcConfig = {
    vam = {
      knownPlugins = pkgs.vimPlugins;
      pluginDictionaries = [
        { name = "vim-nix"; }
      ];
    };
  };
}
