{
  description = "digital ocean droplet for fina";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    buildbot-nix.url = "github:nix-community/buildbot-nix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
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
      fina = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          ./digitalOcean/configuration.nix
        ];
      };
    };
  };
}
