{
  description = "NixOS configuration for WSL";

  inputs = {
    wsl.url = "github:nix-community/NixOS-WSL";
    nixpkgs.follows = "wsl/nixpkgs";
    flake-utils.follows = "wsl/flake-utils";
  };

  outputs = { self, wsl, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
          specialArgs = { inherit (wsl.nixosModules) wsl; };
        };
      }
    );
}
