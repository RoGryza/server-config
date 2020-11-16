{ config, pkgs, ... }:
{
  services.taskserver = {
    enable = true;
    listenHost = "0.0.0.0";
    fqdn = config.my.domain;
    dataDir = "${config.my.persistentVolume}/taskserver";
  };
}
