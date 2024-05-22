{
  description = "Rust for the xtensa architecture";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    esp-rust = {
      type = "git";
      url = "https://github.com/esp-rs/rust";
      submodules = true;
      shallow = true;
      flake = false;
    };
    esp-llvm = {
      url = "github:espressif/llvm-project/esp-17.0.1_20240419";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, esp-rust, esp-llvm }:
    let
      forSystems = systems: f:
        builtins.foldl' (attrs: system: nixpkgs.lib.recursiveUpdate attrs (f system)) { } systems;
      rustSupportedPlatforms = nixpkgs.outputs.legacyPackages.x86_64-linux.rustc.meta.platforms;
      targetPlatforms = with nixpkgs.lib; intersectLists systems.flakeExposed rustSupportedPlatforms;
    in
    forSystems targetPlatforms (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.${system} = {
          default = self.packages.${system}.rust;

          llvm = pkgs.callPackage ./llvm.nix {
            monorepoSrc = esp-llvm // { name = "source"; };
          };

          rust = pkgs.callPackage ./rust.nix {
            rustPackages = pkgs.rustPackages_1_77;
            src = esp-rust;
            vendor = true;
            llvmForEsp32 = self.packages.${system}.llvm;
          };
        };

        apps.${system} = {
          default = self.apps.${system}.install;

          install = {
            type = "app";
            program = pkgs.lib.getExe (pkgs.writeShellApplication {
              name = "install-esp32-toolchain";
              # runtimeInputs = [ pkgs.rustup ];
              text = ''
                printf "esp-rust is installed to: "
                # rustup toolchain link esp ${self.packages.${system}.rust.sysroot}
                mkdir -p "''${RUSTUP_HOME:-$HOME/.rustup}/toolchains"
                nix-store --add-root "''${RUSTUP_HOME:-$HOME/.rustup}/toolchains/esp" --realise ${self.packages.${system}.rust.sysroot}
              '';
            });
          };

          uninstall = {
            type = "app";
            program = pkgs.lib.getExe (pkgs.writeShellApplication {
              name = "uninstall-esp32-toolchain";
              text = "rm -v \"\${RUSTUP_HOME:-$HOME/.rustup}/toolchains/esp\"";
            });
          };
        };
      });
}
