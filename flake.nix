{
  description = "ble.sh";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ble-sh = {
      type = "git";
      url = "https://github.com/akinomyoga/ble.sh.git";
      ref = "refs/heads/master";
      submodules = true;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ble-sh }: {
    overlays.default = final: prev: {
      blesh = self.packages.${prev.system}.default;
    };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    rec {
      packages.default = pkgs.stdenv.mkDerivation
        {
          name = "ble.sh";
          src = ble-sh;
          patchPhase = ''
            sed -i"" "/git submodule update/d" GNUmakefile
          '';
          installFlags = [ "PREFIX=$(out)" ];
          checkInputs = with pkgs; [ bashInteractive glibcLocales ];
          preCheck = "export LC_ALL=en_US.UTF-8";
          postInstall = ''
            mkdir -p "$out/bin"
            cat <<EOF >"$out/bin/blesh-share"
            #!${pkgs.runtimeShell}
            # Run this script to find the ble.sh shared folder
            # where all the shell scripts are living.
            echo "$out/share/blesh"
            EOF
            chmod +x "$out/bin/blesh-share"

            mkdir -p "$out/share/lib"
            cat <<EOF >"$out/share/lib/_package.sh"
            _ble_base_package_type=nix
            function ble/base/package:nix/update {
              echo "Ble.sh is installed by Nix. You can update it there." >&2
              return 1
            }
            EOF
          '';
        };

      apps.default =
        let
          bashrc = pkgs.writeText "bashrc" ''
            [[ -f blerc ]] && rcfile=$(readlink -f blerc)
            source "${packages.default}/share/blesh/ble.sh" --attach=none ''${rcfile:+--rcfile=\"$rcfile\"}

            [[ -f bashrc ]] && source bashrc && echo bashrc at the current path is sourced
            echo ble.sh is "$(${packages.default}/bin/blesh-share)/ble.sh"
            echo rcfile is "''${rcfile:-not specified}"
            echo

            [[ ''${BLE_VERSION-} ]] && ble-attach
          '';
        in
        flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "blesh-enabled-bash";
            runtimeInputs = [ packages.default pkgs.bashInteractive ];
            text = ''
              exec ${pkgs.bashInteractive}/bin/bash --noprofile --rcfile "${bashrc}" "$@"
            '';
          };
        };
    });
}
