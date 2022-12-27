{pkgs ? import <nixpkgs> {}}: let
  pythonEnv = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
  };
in
  pythonEnv.env.overrideAttrs (oldAttrs: {
    buildInputs = with pkgs; [
      mosh
      gnupg
      restic
      terraform
    ];

    shellHook = ''
      if [ -d .secrets ]; then
        export "DIGITALOCEAN_API_TOKEN=$(gpg -qad .secrets/keys/digitalocean.gpg || true)"
        export "DIGITALOCEAN_ACCESS_TOKEN=$DIGITALOCEAN_API_TOKEN"
        export "CLOUDFLARE_API_TOKEN=$(gpg -qad .secrets/keys/cloudflare.gpg || true)"
        export "B2_APPLICATION_KEY_ID=$(gpg -qad .secrets/keys/backblaze/id.gpg || true)"
        export "B2_APPLICATION_KEY=$(gpg -qad .secrets/keys/backblaze/key.gpg || true)"
        export "AWS_ACCESS_KEY_ID=$B2_APPLICATION_KEY_ID"
        export "AWS_SECRET_ACCESS_KEY=$B2_APPLICATION_KEY"
      fi
    '';
  })
