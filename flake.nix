{
  # TODO: Figure out how to override this locally.
  inputs.nixpkgs.url = "git+file:///home/delroth/work/nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.delroth-net.url = "git+https://github.com/delroth/delroth.net?submodules=1";
  inputs.delroth-net.inputs.nixpkgs.follows = "nixpkgs";

  inputs.protonvpn-pmp-transmission.url = "github:delroth/protonvpn-pmp-transmission";
  inputs.protonvpn-pmp-transmission.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, delroth-net, nixpkgs, home-manager, protonvpn-pmp-transmission, ... }@attrs: {
    colmena = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          delroth-net.overlay
          protonvpn-pmp-transmission.overlay
        ];
      };

      machines = import ./machines;

      mkNormalDeployment = name: machineMod: {
        name = "${name}.delroth.net";
        value = { config, ... }: {
          _module.args.machineName = name;
          deployment.targetHost = config.my.networking.fqdn;

          imports = [
            home-manager.nixosModules.home-manager

            machineMod
          ];
        };
      };
    in {
      meta.name = "*.delroth.net prod infra";
      meta.nixpkgs = pkgs;
      meta.specialArgs = attrs;
    } // (pkgs.lib.mapAttrs' mkNormalDeployment machines);
  };
}
