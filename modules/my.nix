{ lib, ... }:
with lib;
{
  options = {
    # TODO automate DNS based on this
    my.domain = mkOption { type = types.str; };

    my.admin.user = mkOption { type = types.str; };
    my.admin.keys = mkOption { type = types.listOf types.path; };

    my.persistentVolume = mkOption {
      type = types.str;
      default = "/storage";
    };
  };
}
