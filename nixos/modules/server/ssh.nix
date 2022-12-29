{
  config,
  lib,
  ...
}: let
  inherit (builtins) length;
  inherit (lib) mkDefault mkOption;
  inherit (lib.strings) concatMapStrings concatStringsSep optionalString;
in {
  options = let
    inherit (lib.options) mergeOneOption;
    inherit (lib.types) bool enum listOf string;
  in {
    services.openssh = {
      acceptEnv = mkOption {
        type = listOf string;
        default = [];
      };

      authenticationMethods = mkOption {
        type =
          listOf (listOf (enum [
            "gssapi-with-mic"
            "hostbased"
            "keyboard-interactive"
            "none"
            "password"
            "publickey"
          ]))
          // {
            merge = mergeOneOption;
          };
        default = [];
      };

      disableForwarding = mkOption {
        type = bool;
        default = false;
      };
    };
  };

  config = let
    cfg = config.services.openssh;
  in {
    programs.mosh.enable = true;

    services.openssh = {
      enable = true;

      acceptEnv = [
        "LANG"
        "LC_CTYPE"
        "LC_NUMERIC"
        "LC_TIME"
        "LC_COLLATE"
        "LC_MONETARY"
        "LC_MESSAGES"

        "LC_PAPER"
        "LC_NAME"
        "LC_ADDRESS"
        "LC_TELEPHONE"
        "LC_MEASUREMENT"

        "LC_IDENTIFICATION"
        "LC_ALL"
        "LANGUAGE"

        "XMODIFIERS"
      ];

      disableForwarding = true;

      permitRootLogin = "no";
      authenticationMethods = mkDefault [["publickey"]];
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;

      extraConfig = ''
        ${
          concatMapStrings (env: ''
            AcceptEnv ${env}
          '')
          cfg.acceptEnv
        }

        DisableForwarding ${
          if cfg.disableForwarding
          then "yes"
          else "no"
        }

        KbdInteractiveAuthentication ${
          if cfg.kbdInteractiveAuthentication
          then "yes"
          else "no"
        }

        ${
          optionalString (length (cfg.authenticationMethods) > 0)
          ''
            AuthenticationMethods ${
              concatStringsSep " " (
                map (
                  concatStringsSep ","
                )
                cfg.authenticationMethods
              )
            }
          ''
        }
      '';
    };
  };
}
