{config, lib, ...}:

let
  my = import ../.;
in
{
  options.my.stateless.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether the server should be considered to be "stateless", aka. its whole
      state is defined by its NixOS configuration. Examples that would be
      stateful would be important data files, servers that need manual action
      to restart, etc.
    '';
  };

  config = lib.mkIf (config.my.stateless.enable) {
    # Reboot on OOM instead of trying to recover.
    boot.kernel.sysctl = {
      "vm.panic_on_oom" = true;
      "kernel.panic" = 3;
    };
  };
}
