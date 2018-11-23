with import <nixpkgs> {};

let
  base = {
    network.description = "*.delroth.net staging infra";
  };

  machines = import ../machines;

  # Modifies a machine definition to add deployment related information for
  # staging deployments (→ local VirtualBox testing instance).
  makeStagingDeployment = name: machineMod:
    lib.nameValuePair
      ("staging-${name}")
      ({ config, ... }: {
        _module.args = {
          staging = true;
          machineName = "staging-${name}";
        };

        imports = [ machineMod ];

        deployment.targetEnv = "virtualbox";
        deployment.virtualbox.vcpu = 2;
        deployment.virtualbox.memorySize = 4096;
        deployment.virtualbox.headless = true;
      });
in
  base // (lib.mapAttrs' makeStagingDeployment machines)
