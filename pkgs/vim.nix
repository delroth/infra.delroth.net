{ vim_configurable, vimPlugins }:

vim_configurable.customize {
  name = "vim";
  vimrcConfig = {
    vam = {
      knownPlugins = vimPlugins;
      pluginDictionaries = [
        { name = "vim-nix"; }
      ];
    };
  };
}
