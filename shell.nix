{ pkgs ? import ./nix/nixpkgs.nix {} }:
pkgs.mkShell {
  buildInputs = [pkgs.niv pkgs.nixops];
}
