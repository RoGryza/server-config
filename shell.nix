{ pkgs ? import ./nix/nixpkgs.nix {}, }:
let
  overrides = import ./overrides.nix { inherit pkgs; };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    niv
    poetry
    # TODO
    # (pkgs.poetry2nix.mkPoetryEnv {
    #   projectDir = ./.;
    #   overrides = pkgs.poetry2nix.overrides.withDefaults overrides;
    # })
  ];
}
