{...}: {
  imports = [
    ./ssh.nix
  ];

  options = {
  };

  config = {
    system.stateVersion = "23.05";

    services.chrony.enable = true;
  };
}
