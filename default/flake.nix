{
  description = "";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forSystems = systems: f:
        builtins.foldl' (attrs: system: nixpkgs.lib.recursiveUpdate attrs (f system)) { } systems;
      forAllSystems = forSystems nixpkgs.lib.systems.flakeExposed;
    in
    forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.${system}.default = pkgs.stdenv.mkDerivation rec {
          pname = "";
          version = "";
          src = pkgs.fetchurl { };
        };
      });
}
