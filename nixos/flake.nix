{
  description = "digital ocean droplet for bip";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    buildbot-nix.url = "github:nix-community/buildbot-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      bip-droplet = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          ./digitalOcean/configuration.nix
        ];
      };
    };
  };
}
