{
  description = "lfortran";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    lfortran = {
      url = "github:lfortran/lfortran";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, lfortran }: {
    overlays.default = final: prev: {
      lfortran = self.packages.${prev.system}.default;
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
      packages.default = pkgs.callPackage ./. { llvmPackages = pkgs.llvmPackages_11; };
      packages.latest = packages.default.overrideAttrs (prev: rec {
        version = getVersion lfortran;
        src = lfortran;
        nativeBuildInputs = with pkgs; [ python3Minimal bison re2c ] ++ prev.nativeBuildInputs;
        prePatch = ''
          echo '#!/usr/bin/env bash' >ci/version.sh
          echo 'echo "${version}" >version' >>ci/version.sh
          patchShebangs *.sh ci/*.sh
        '';
        preConfigure = "./build0.sh";
      });
    });
}
