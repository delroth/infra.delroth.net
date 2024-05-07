{
  # TODO: Figure out how to override this locally.
  inputs.nixpkgs.url = "git+file:///home/delroth/work/nixpkgs";

  inputs.lix.url = "git+https://git@git.lix.systems/lix-project/nixos-module";
  inputs.lix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.delroth-net.url = "git+https://github.com/delroth/delroth.net?submodules=1";
  inputs.delroth-net.inputs.nixpkgs.follows = "nixpkgs";

  inputs.glome-nixos.url = "github:delroth/glome-nixos";
  inputs.glome-nixos.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixfmt.url = "github:NixOS/nixfmt";

  inputs.protonvpn-pmp-transmission.url = "github:delroth/protonvpn-pmp-transmission";
  inputs.protonvpn-pmp-transmission.inputs.nixpkgs.follows = "nixpkgs";
  inputs.protonvpn-pmp-transmission.inputs.poetry2nix.follows = "poetry2nix";

  inputs.publibike-locator.url = "github:delroth/publibike-locator";
  inputs.publibike-locator.inputs.nixpkgs.follows = "nixpkgs";

  inputs.label-approved.url = "git+file:///home/delroth/work/label-approved";
  inputs.label-approved.inputs.nixpkgs.follows = "nixpkgs";
  inputs.label-approved.inputs.poetry2nix.follows = "poetry2nix";

  outputs =
    {
      self,
      lix,
      delroth-net,
      glome-nixos,
      nixpkgs,
      home-manager,
      label-approved,
      nixfmt,
      protonvpn-pmp-transmission,
      ...
    }@attrs:
    {
      formatter.x86_64-linux = nixfmt.packages.x86_64-linux.default;

      colmena =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              delroth-net.overlay
              glome-nixos.overlay
              protonvpn-pmp-transmission.overlay
            ];
            config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "elasticsearch" ];
          };

          machines = import ./machines;

          mkNormalDeployment = name: machineMod: {
            name = "${name}.delroth.net";
            value =
              { config, ... }:
              {
                _module.args.machineName = name;
                deployment.targetHost = config.my.networking.fqdn;

                imports = [
                  glome-nixos.nixosModules.glome
                  home-manager.nixosModules.home-manager
                  label-approved.nixosModules.default
                  lix.nixosModules.default

                  machineMod
                ];
              };
          };
        in
        {
          meta.name = "*.delroth.net prod infra";
          meta.nixpkgs = pkgs;
          meta.specialArgs = attrs;
        }
        // (pkgs.lib.mapAttrs' mkNormalDeployment machines);
    };
}
