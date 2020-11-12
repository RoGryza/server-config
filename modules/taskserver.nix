{ config, pkgs, ... }:
{
  services.taskserver = {
    enable = true;
    listenHost = "0.0.0.0";
    fqdn = "tw.rogryza.me";
    organisations.personal = {
      users = ["rogryza"];
      groups = ["rogryza"];
    };
    dataDir = "/storage/taskserver";
  };
}
