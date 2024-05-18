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
            llvmForEsp32 = self.packages.${system}.llvm.overrideAttrs {
              passthru.dev = self.packages.${system}.llvm;
            };
          };
        };
      });
}
