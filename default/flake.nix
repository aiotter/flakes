{
  description = "";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      forSystems = with nixpkgs.lib; systems: f: genAttrs systems (system: f system);
      forAllSystems = f: forSystems nixpkgs.lib.systems.flakeExposed;
    in
    forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "";
          version = "";
          src = pkgs.fetchurl { };
        };
      });
}
