let
  pkgs = import <nixpkgs> {};
  base = {
    network = {
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
        machineName = name;
      };

      imports = [ machineMod ];

      deployment.targetHost = config.my.networking.fqdn;
    };
  };
in
  base // (pkgs.lib.mapAttrs' makeNormalDeployment machines)
