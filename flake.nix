{
  description = "python-build from pyenv";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyenv = {
      url = "github:pyenv/pyenv";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, pyenv }: {
    overlays.default = final: prev: {
      python-build = self.packages.${prev.system}.default;
    };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      getVersion = input: with input; "unstable-${builtins.substring 0 4 lastModifiedDate}-${builtins.substring 4 2 lastModifiedDate}-${builtins.substring 6 2 lastModifiedDate}";
    in
    rec {
      packages.default = pkgs.stdenv.mkDerivation (prev: rec {
        pname = "python-build";
        version = getVersion pyenv;
        src = pyenv;
        sourceRoot = "source/plugins/python-build";
        buildInputs = with pkgs; [ bash readline zlib openssl gcc gnumake ];
        installPhase = ''
          PREFIX=$out ./install.sh
        '';
      });
    });
}
