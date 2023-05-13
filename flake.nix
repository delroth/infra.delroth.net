{
  # TODO: Figure out how to override this locally.
  inputs.nixpkgs.url = "git+file:///home/delroth/work/nixpkgs";

  outputs = { self, nixpkgs, ... }@attrs: {
    colmena = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      machines = import ./machines;

      mkNormalDeployment = name: machineMod: {
        name = "${name}.delroth.net";
        value = { config, ... }: {
          _module.args.machineName = name;
          deployment.targetHost = config.my.networking.fqdn;

          imports = [ machineMod ];
        };
      };
    in {
      meta.name = "*.delroth.net prod infra";
      meta.nixpkgs = pkgs;
      meta.specialArgs = attrs;
    } // (pkgs.lib.mapAttrs' mkNormalDeployment machines);
  };
}
