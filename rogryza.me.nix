{ password }:
{
  network.description = "rogryza.me";
  resources.hcloudSshKeys.key = {
    publicKey = builtins.readFile ./keys/id_rsa.pub;
  };
  resources.hcloudVolumes.storage = {
    size = 10;
    location = "hel1";
  };
  main = { pkgs, resources, ... }: {
    deployment.targetEnv = "hcloud";
    deployment.hcloud = {
      serverType = "cx11";
      location = "hel1";
      sshKeys = [ resources.hcloudSshKeys.key ];
      volumes = [
        {
          volume = resources.hcloudVolumes.storage;
          mountPoint = "/storage";
          fileSystem = {
            fsType = "ext4";
            autoFormat = true;
          };
        }
      ];
    };

    imports = [
      <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
      ./fetchHetznerKeys.nix
      ./modules/taskserver.nix
    ];
    nix.trustedUsers = [ "rogryza" ];
    services.fetchHetznerKeys.enable = true;

    networking.hostName = "rogryza";
    time.timeZone = "Europe/Amsterdam";

    services.openssh.enable = true;
    services.openssh.openFirewall = true;
    services.openssh.passwordAuthentication = false;
    # services.openssh.permitRootLogin = "no"; # TODO disable root login without breaking nixops
    programs.mosh.enable = true;

    networking.firewall.enable = true;

    users.mutableUsers = false;
    users.groups.wheel = {};
    # TODO change root to auto-generated keys
    # TODO change root password
    users.users.root.password = password;
    users.users.root.openssh.authorizedKeys.keyFiles = [ ./keys/id_rsa.pub ];
    deployment.keys.rogryza-passsword.text = password;
    users.groups.rogryza = {};
    users.users.rogryza = {
      isNormalUser = true;
      createHome = true;
      group = "rogryza";
      extraGroups = [ "wheel" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = [ ./keys/id_rsa.pub ];
      passwordFile = "/run/keys/rogryza-password"; # TODO this isn't working, maybe it's fetching the file from the local machine?
    };
  };
}
