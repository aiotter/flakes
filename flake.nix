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
        buildInputs = pkgs.python3.buildInputs;
        nativeBuildInputs = [pkgs.makeWrapper];
        installPhase = ''
          PREFIX=$out ./install.sh
          wrapProgram $out/bin/python-build \
            --set PYTHON_BUILD_SKIP_HOMEBREW 1 \
            --set PYTHON_CONFIGURE_OPTS "${pkgs.lib.concatStringsSep " " pkgs.python3.configureFlags}" \
            --set CPPFLAGS "${pkgs.python3.CPPFLAGS}" \
            --set LDFLAGS "${pkgs.python3.LDFLAGS}" \
            --set LIBS "${pkgs.python3.LIBS}"
        '';
      });
    });
}
