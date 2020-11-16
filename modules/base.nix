{ pkgs, config, ... }:
let
  inherit (config.my) admin;
in
{
    imports = [
      <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
      ../fetchHetznerKeys.nix
    ];

    nix.trustedUsers = [ admin.user ];
    services.fetchHetznerKeys.enable = true;

    services.openssh.enable = true;
    services.openssh.openFirewall = true;
    services.openssh.passwordAuthentication = false;
    # services.openssh.permitRootLogin = "no"; # TODO disable root login without breaking nixops
    programs.mosh.enable = true;

    networking.firewall.enable = true;

    users.mutableUsers = false;
    users.groups.wheel = {};
    users.groups."${admin.user}" = {};
    users.users."${admin.user}" = {
      isNormalUser = true;
      createHome = true;
      group = admin.user;
      extraGroups = [ "wheel" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = admin.keys;
    };
}
