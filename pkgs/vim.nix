{ vim-full, vimPlugins }:

vim-full.customize {
  name = "vim";
  vimrcConfig = {
    vam = {
      knownPlugins = vimPlugins;
      pluginDictionaries = [ { name = "vim-nix"; } ];
    };
  };
}
