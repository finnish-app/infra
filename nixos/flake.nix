{
  description = "digital ocean droplet for finnish";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [];
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      ubuntu-s-nixos-test = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./digitalOcean/configuration.nix
        ];
      };
    };
  };
}
