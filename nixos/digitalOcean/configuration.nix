{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    inputs.home-manager.nixosModules.default
    inputs.buildbot-nix.nixosModules.buildbot-master
    inputs.buildbot-nix.nixosModules.buildbot-worker
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

  environment.systemPackages = with pkgs; [git neovim zellij];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "fina";
  networking.domain = "finnish.ovh";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0V2EeJT/g1fGeolumPCyCIjpYVX5WT91H3I7HcZj8N nic@desktop''];
  system.stateVersion = "23.11";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
      "root" = import /root/infra.git/main/nixos/digitalOcean/home.nix;
    };
    backupFileExtension = "backup";
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 10";
    flake = "/root/infra.git/main/nixos";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;

    enableTCPIP = true;
    # settings.port = 6543;

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

  programs.direnv.enable = true;

  services.buildbot-master.buildbotUrl = lib.mkForce "https://buildbot.finnish.ovh/";
  services.buildbot-nix.master = {
    enable = true;
    admins = ["nicolasauler"];

    domain = "buildbot.finnish.ovh";

    jobReportLimit = 20;

    github = {
      authType.app = {
        id = 1061359;
        secretKeyFile = /root/infra.git/main/nixos/digitalOcean/app-secret.key;
      };

      oauthId = "Iv23liHHz2RUuo5PHXOy";
      oauthSecretFile = pkgs.writeText "oauth-secret.key" "hey hey";

      webhookSecretFile = pkgs.writeText "webhook-secret" "uau uau";
      topic = "build-with-buildbot";
    };

    workersFile = pkgs.writeText "workers.json" ''
      [
        { "name": "fina", "pass": "password", "cores": 4 }
      ]
    '';

    cachix = {
      enable = true;
      name = "fina";

      # One of the following is required:
      # auth.signingKey.file = "/var/lib/secrets/cachix-key";
      auth.authToken.file = pkgs.writeText "cachix-token" "hi hi";
    };
  };

  services.buildbot-nix.worker = {
    enable = true;
    workerPasswordFile = pkgs.writeText "worker-pass" "password";
  };

  services.caddy = {
    enable = true;
    virtualHosts."finnish.ovh".extraConfig = ''
      reverse_proxy localhost:8000
    '';

    virtualHosts."buildbot.finnish.ovh".extraConfig = ''
      reverse_proxy localhost:8080
    '';
  };

  services.nginx = {
    defaultHTTPListenPort = 8080;
    # virtualHosts.${config.services.buildbot-nix.master.domain} = {
    #   forceSSL = true;
    #   enableACME = true;
    # };
  };
}
