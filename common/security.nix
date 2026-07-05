{
  config,
  lib,
  secrets,
  ...
}:

{
  # Let's Encrypt related configuration.
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "acme@delroth.net";

  # User namespaces are required for sandboxing. Better than nothing imo.
  security.allowUserNamespaces = true;

  # Hyperthreading is not a concern for single-user environments. PTI mostly
  # isn't either.
  security.allowSimultaneousMultithreading = true;
  security.forcePageTableIsolation = false;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = # Require password if set.
    config.users.users.delroth.hashedPassword != null;

  # TODO: Once more build capacity has been converted to NixOS, add hostname
  # to the seed as well for more diversity.
  boot.kernel.randstructSeed = "${secrets.randstructSeed}";

  # Imported from hardened.nix.
  nix.settings.allowed-users = lib.mkDefault [ "@users" ];
  security.lockKernelModules = lib.mkDefault true;
  security.protectKernelImage = lib.mkDefault true;
  security.unprivilegedUsernsClone = lib.mkDefault true;
  security.apparmor.enable = lib.mkDefault true;
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = lib.mkOverride 500 1;
  boot.kernel.sysctl."kernel.kptr_restrict" = lib.mkOverride 500 2;
  boot.kernel.sysctl."net.core.bpf_jit_enable" = lib.mkDefault false;
  boot.kernel.sysctl."kernel.ftrace_enabled" = lib.mkDefault false;
}
