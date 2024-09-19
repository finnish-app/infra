{
  description = "Finnish Digital ocean devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    flake-utils,
    agenix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        beyla = pkgs.stdenv.mkDerivation {
          pname = "grafana_beyla";
          version = "v1.8.4-alpha";

          src = pkgs.fetchzip {
            url = "https://github.com/grafana/beyla/releases/download/v1.8.4-alpha/beyla-linux-amd64-v1.8.4-alpha.tar.gz";
            hash = "sha256-hlXgm71bMhmP2QYBTMsU4sEQILpAxdGOJd1DUr6cdW8=";
            stripRoot = false;
          };

          installPhase = ''
            mkdir -p $out/bin
            cp $src/beyla $out/bin
          '';
        };
        rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
        # rust = pkgs.rust-bin.beta.latest.default;
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              agenix.packages.${system}.default
              beyla
              rust
            ];

            shellHook = ''
              # https://grafana.com/orgs/onic/stacks/1039590/otlp-info
              # https://grafana.com/docs/beyla/latest/tutorial/getting-started/
              export BEYLA_OPEN_PORT=8080
              export BEYLA_TRACE_PRINTER=text
              export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
              export OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-sa-east-1.grafana.net/otlp"
              export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic <TODO: add agenix or sops secrets>"

              # debug the beyla stuff
              # printf "Beyla: ${beyla}\n"
              # printf ${config.age.secrets.secret1.path}
            '';
          };
        }
    );
}
