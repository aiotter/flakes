{
  description = "pivy";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pivy = {
      url = "github:arekinath/pivy";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, pivy }: {
    overlays.default = final: prev: {
      pivy = self.packages.${prev.system}.default;
    };
    overlays.latest = final: prev: {
      pivy = self.packages.${prev.system}.latest;
    };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      getVersion = input: with input; "unstable-${builtins.substring 0 4 lastModifiedDate}-${builtins.substring 4 2 lastModifiedDate}-${builtins.substring 6 2 lastModifiedDate}";
    in
    rec {
      packages.default = pkgs.callPackage ./. { };
      packages.latest = packages.default.overrideAttrs (prev: {
        version = getVersion pivy;
        srcs = [ pivy ] ++ pkgs.lib.drop 1 prev.srcs;
      });
    });
}
