{
  description = "iproute2mac";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    iproute2mac = {
      url = "github:brona/iproute2mac";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, iproute2mac }:
    let
      darwinSystems = with flake-utils.lib.system; [ x86_64-darwin aarch64-darwin ];
    in
    {
      overlays.default = final: prev: {
        iproute2 = self.packages.${prev.system}.default;
      };
    } // flake-utils.lib.eachSystem darwinSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "iproute2mac";
          version = with iproute2mac; "unstable-${builtins.substring 0 4 lastModifiedDate}-${builtins.substring 4 2 lastModifiedDate}-${builtins.substring 6 2 lastModifiedDate}";
          src = iproute2mac;

          buildInputs = [ pkgs.python3 ];

          installPhase = ''
            mkdir -p $out/bin
            cp src/ip.py $out/bin/ip
            chmod +x $out/bin/ip
          '';

          meta = {
            description = "CLI wrapper for basic network utilites on Mac OS X inspired with iproute2 on Linux systems - ip command.";
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/brona/iproute2mac";
            platforms = pkgs.lib.platforms.darwin;
            mainProgram = "ip";
          };
        };
      });
}
