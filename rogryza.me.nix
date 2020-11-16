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
  main = { config, pkgs, resources, ... }: {
    deployment.targetEnv = "hcloud";
    deployment.hcloud = {
      serverType = "cx11";
      location = "hel1";
      sshKeys = [ resources.hcloudSshKeys.key ];
      volumes = [
        {
          volume = resources.hcloudVolumes.storage;
          mountPoint = config.my.persistentVolume;
          fileSystem = {
            fsType = "ext4";
            autoFormat = true;
          };
        }
      ];
    };

    imports = [
      ./modules/base.nix
      ./modules/my.nix
      # ./modules/taskserver.nix
    ];

    my.domain = "rogryza.me";
    my.admin.user = "rogryza";
    my.admin.keys = [ ./keys/id_rsa.pub ];

    services.taskserver.organisations.personal = {
      users = ["rogryza"];
      groups = ["rogryza"];
    };

    networking.hostName = "rogryza-me";
    time.timeZone = "Europe/Amsterdam";

    # TODO change root to auto-generated keys
    # TODO change root password
    users.users.root.password = password;
    users.users.root.openssh.authorizedKeys.keyFiles = [ ./keys/id_rsa.pub ];

    deployment.keys.rogryza-passsword.text = password;
    users.users.rogryza.passwordFile = "/run/keys/rogryza-password"; # TODO this isn't working, maybe it's fetching the file from the local machine?
  };
}
