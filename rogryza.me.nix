{ host, password }:
{
  network.description = "rogryza.me";
  main = { config, pkgs, ... }:
  let
  in {
    deployment.targetHost = host;

    imports = [
      <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
      ./modules/taskserver.nix
    ];
    nix.maxJobs = pkgs.lib.mkDefault 1;
    nix.trustedUsers = ["rogryza"];

    boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "xhci_pci" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    system.stateVersion = "20.03";
    boot.loader.grub.devices = ["/dev/sda"];

    fileSystems."/" = { device = "/dev/sda"; fsType = "ext4"; };
    swapDevices = [ ];

    networking.hostName = "rogryza";
    networking.interfaces.ens3.useDHCP = true;

    time.timeZone = "Europe/Amsterdam";

    services.openssh.enable = true;
    services.openssh.openFirewall = true;
    services.openssh.passwordAuthentication = false;
    # services.openssh.permitRootLogin = "no"; # TODO disable root login without breaking nixops

    networking.firewall.enable = true;

    users.groups.wheel = {};
    # TODO change root to auto-generated keys
    users.users.root.openssh.authorizedKeys.keyFiles = [./keys/id_rsa.pub];
    deployment.keys.rogryza-passsword.text = password;
    users.groups.rogryza = {};
    users.users.rogryza = {
      isNormalUser = true;
      createHome = true;
      group = "rogryza";
      extraGroups = ["wheel"];
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = [./keys/id_rsa.pub];
      passwordFile = "/run/keys/rogryza-password";
    };
  };
}
