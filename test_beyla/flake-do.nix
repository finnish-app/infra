{
  description = "Finnish Digital ocean devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    flake-utils,
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
              beyla
              rust
            ];

            shellHook = ''
              # debug the beyla stuff
              # printf "Beyla: ${beyla}\n"
            '';
          };
        }
    );
}
