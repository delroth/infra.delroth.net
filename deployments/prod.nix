let
  pkgs = import <nixpkgs> {};
  base = {
    network = {
      inherit pkgs;
      description = "*.delroth.net prod infra";
    };
  };

  machines = import ../machines;

  # Modifies a machine definition to add deployment related information for
  # normal deployments (→ NixOS target server).
  makeNormalDeployment = name: machineMod: {
    name = "${name}.delroth.net";
    value = { config, ... }: {
      _module.args = {
        staging = false;
        machineName = name;
      };

      imports = [ machineMod ];

      deployment.targetHost = config.networking.hostName;
    };
  };
in
  base // (pkgs.lib.mapAttrs' makeNormalDeployment machines)
