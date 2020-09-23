{ sources ? import ./sources.nix }:
let
  nivOverlay = _: pkgs: {
    niv = (pkgs.callPackage sources.niv {}).niv;
  };
in
  import sources.nixpkgs {
    overlays = [nivOverlay];
  }
