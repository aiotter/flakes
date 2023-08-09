{ lib, pkgs, config, modulesPath, wsl, ... }:

with lib;
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    wsl
  ];

  wsl = {
    enable = true;
    defaultUser = "aiotter";
    startMenuLaunchers = true;

    # Enable native Docker support
    docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "22.05";

  environment.systemPackages = [
    pkgs.git
    pkgs.coreutils
    pkgs.gawk
    pkgs.unixtools.ifconfig
  ];

  users.users.aiotter = {
    isNormalUser = true;
    home = "/home/aiotter";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEcSApna9zs6r6/+mOIFxbjuDW7Qsph72ym+F25FU9/NR4KOB97Z4Z4884O4x2j38FCDwxfdKCvYLMWm9pMnUcU= auth@aiotter.com"
    ];
  };

  services.openssh.enable = true;
  virtualisation.docker.enable = true;
}
