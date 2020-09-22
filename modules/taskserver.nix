{ config, pkgs, ... }:
{
  services.taskserver = {
    enable = true;
    listenHost = config.deployment.targetHost;
    fqdn = "tw.rogryza.me";
    organisations.personal = {
      users = ["rogryza"];
      groups = ["rogryza"];
    };
  };
}
