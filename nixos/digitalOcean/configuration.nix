{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-substituters = [
      "https://cache.nixos.org/"
    ];
    substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://hyprland.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  environment.systemPackages = with pkgs; [neovim zellij];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "ubuntu-s-nixos-test";
  networking.domain = "";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0V2EeJT/g1fGeolumPCyCIjpYVX5WT91H3I7HcZj8N nic@desktop''];
  system.stateVersion = "23.11";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;

    enableTCPIP = true;
    settings.port = 6543;

    # ensureDatabases = ["finapp"];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust

      #type database DBuser origin-address auth-method
      # ipv4
      host  all      all     127.0.0.1/32   trust
      # ipv6
      host all       all     ::1/128        trust
    '';

    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE finapp WITH LOGIN PASSWORD 'finapp' CREATEDB;
      CREATE DATABASE finapp;
      GRANT ALL PRIVILEGES ON DATABASE finapp TO finapp;
    '';
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."finnish.ovh".extraConfig = ''
      respond "Hello, world!"
    '';
  };
}
