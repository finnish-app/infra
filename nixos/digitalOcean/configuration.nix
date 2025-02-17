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
      "https://fina.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://hyprland.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "fina.cachix.org-1:Xaf+3HF5Wffl4Gtpi68Yz/wRQw0bH8tNVTlMnkLSRQc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  environment.systemPackages = with pkgs; [git neovim zellij];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "bip-droplet";
  networking.domain = "fina.center";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0V2EeJT/g1fGeolumPCyCIjpYVX5WT91H3I7HcZj8N nic@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhY9j08IXIGos+epdkykKEfD6DGPe+Jl+/BurFBw4IR nic@xpsbipa"
  ];
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

  services.buildbot-master.buildbotUrl = lib.mkForce "https://buildbot.fina.center/";
  services.buildbot-nix.master = {
    enable = true;
    admins = ["nicolasauler"];

    domain = "buildbot.fina.center";

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
    virtualHosts."fina.center" = {
      extraConfig = ''
        reverse_proxy localhost:8000
      '';
      serverAliases = ["www.fina.center"];
    };

    virtualHosts."buildbot.fina.center".extraConfig = ''
      reverse_proxy localhost:8080
    '';

    virtualHosts."grafana.fina.center".extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';

    virtualHosts."influx.fina.center".extraConfig = ''
      reverse_proxy 127.0.0.1:8086
    '';

    virtualHosts."video.fina.center".extraConfig = ''
      redir https://youtu.be/AUdKfNFCxbs permanent
    '';

    virtualHosts."model.fina.center".extraConfig = ''
      reverse_proxy 127.0.0.1:9000
    '';
  };

  services.nginx = {
    defaultHTTPListenPort = 8080;
    # virtualHosts.${config.services.buildbot-nix.master.domain} = {
    #   forceSSL = true;
    #   enableACME = true;
    # };
  };

  environment.etc."alloy/client.alloy" = {
    text = ''
      logging {
        level  = "debug"
        format = "logfmt"
      }

      otelcol.receiver.otlp "default" {
        grpc {
          endpoint = "0.0.0.0:4317"
        }

        output {
          logs = [otelcol.processor.batch.default.input]
          traces = [otelcol.processor.batch.default.input]
          metrics = [otelcol.processor.batch.default.input]
        }
      }

      otelcol.processor.batch "default" {
        output {
          logs = [otelcol.exporter.otlphttp.loki.input]
          traces = [otelcol.exporter.otlp.tempo.input]
          metrics = [otelcol.exporter.prometheus.default.input]
        }
      }

      otelcol.exporter.otlphttp "loki" {
        client {
          endpoint = "http://127.0.0.1:3100/otlp"
        }
      }

      otelcol.exporter.otlp "tempo" {
        client {
          endpoint = "http://127.0.0.1:14319"
          tls { insecure = true }
        }
      }

      otelcol.exporter.prometheus "default" {
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      prometheus.remote_write "mimir" {
        endpoint {
          url = "http://127.0.0.1:3300/api/v1/push"
        }
      }

    '';
  };

  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
        };
        # TODO: add agenix / sops-nix
        security.admin_user = "user";
        security.admin_password = "hey hey";
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
          }
          {
            name = "Tempo";
            type = "tempo";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.tempo.settings.server.http_listen_port}";
          }
          {
            name = "Mimir";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.mimir.configuration.server.http_listen_port}/prometheus";
          }
          {
            name = "influxdb";
            type = "influxdb";
            access = "proxy";
            url = "http://127.0.0.1:8086";
            # secureJsonData = {
            #   token = "soon";
            # };
            # jsonData = {
            #   version = "Flux";
            #   organzation = "bamboo";
            #   defaultBucket = "plant0";
            #   tlsSkipVerify = true;
            # };
          }
        ];
      };
    };

    influxdb2 = {
      enable = true;
      settings = {
        http-bind-address = "127.0.0.1:8086";
        log-level = "debug";
      };
    };

    alloy = {
      enable = true;
    };

    loki = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3100;
          grpc_listen_port = 9096;
        };
        auth_enabled = false;

        # common = {
        #  replication_factor = 1;
        # };

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
        };

        schema_config = {
          configs = [
            {
              from = "2024-07-12";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
            cache_ttl = "24h";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };

    tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3200;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = 9095;
        };
        distributor.receivers = {
          otlp.protocols = {
            http.endpoint = "127.0.0.1:14318";
            grpc.endpoint = "127.0.0.1:14319";
          };
        };
        storage.trace = {
          backend = "local";
          wal.path = "/var/lib/tempo/wal";
          local.path = "/var/lib/tempo/blocks";
        };
        ingester = {
          trace_idle_period = "30s";
          max_block_bytes = 1000000;
          max_block_duration = "5m";
        };
        compactor = {
          compaction = {
            compaction_window = "1h";
            max_block_bytes = 100000000;
            compacted_block_retention = "10m";
          };
        };
      };
    };

    mimir = {
      enable = true;
      configuration = {
        multitenancy_enabled = false;
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3300;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = 9097;
        };

        common = {
          storage = {
            backend = "filesystem";
            filesystem.dir = "/var/lib/mimir/metrics";
          };
        };

        blocks_storage = {
          backend = "filesystem";
          bucket_store.sync_dir = "/var/lib/mimir/tsdb-sync";
          filesystem.dir = "/var/lib/mimir/data/tsdb";
          tsdb.dir = "/var/lib/mimir/tsdb";
        };

        compactor = {
          data_dir = "/var/lib/mimir/data/compactor";
          sharding_ring.kvstore.store = "memberlist";
        };

        limits = {
          compactor_blocks_retention_period = "90d";
        };

        distributor = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "memberlist";
          };
        };

        ingester = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "memberlist";
            replication_factor = 1;
          };
        };

        ruler_storage = {
          backend = "filesystem";
          filesystem.dir = "/var/lib/mimir/data/rules";
        };

        store_gateway.sharding_ring.replication_factor = 1;
      };
    };
  };

  systemd.services.alloy = {
    serviceConfig.TimeoutStopSec = 4;
    reloadTriggers = ["/etc/alloy/client.alloy"];
  };
}
