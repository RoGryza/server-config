{
  description = "Selfhosted services config";

  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = import ./shell.nix {inherit pkgs;};
        packages.nixosConfigurations.container = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit pkgs;};

          modules = [
            ./nixos/modules/server
            (_: {
              boot.isContainer = true;
              networking.hostName = "test";
            })
          ];
        };
      }
    );
}
