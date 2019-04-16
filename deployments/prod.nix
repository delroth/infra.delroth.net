with import <nixpkgs> {};

let
  base = {
    network = {
      description = "*.delroth.net prod infra";
      enableRollback = true;
    };
  };

  machines = import ../machines;

  # Modifies a machine definition to add deployment related information for
  # normal deployments (→ NixOS target server).
  makeNormalDeployment = name: machineMod: { config, ... }: {
    _module.args = {
      staging = false;
      machineName = name;
    };

    imports = [ machineMod ];

    deployment.targetEnv = "none";  # NixOS
    deployment.targetHost = config.networking.hostName;
  };
in
  base // (lib.mapAttrs makeNormalDeployment machines)
