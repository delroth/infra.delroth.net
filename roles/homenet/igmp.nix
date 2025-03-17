{
  config,
  lib,
  ...
}:
let
  cfg = config.my.roles.homenet-gateway;
in
{
  config = lib.mkIf cfg.enable {
    # Enable IGMP proxying. Note that default NixOS kernels do not enable
    # CONFIG_IP_MROUTE by default.
    #
    # TODO: actual IGMP proxying.
    boot.kernelPatches = [{
      name = "enable_ip_mroute";
      patch = null;
      extraStructuredConfig = {
        IP_MROUTE = lib.kernel.yes;
      };
    }];
  };
}
