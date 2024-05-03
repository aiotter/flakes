{
  description = "Rust for the xtensa architecture";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    rust = {
      type = "git";
      url = "https://github.com/esp-rs/rust";
      submodules = true;
      shallow = true;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust }:
    let
      forSystems = systems: f:
        builtins.foldl' (attrs: system: nixpkgs.lib.recursiveUpdate attrs (f system)) { } systems;
      rustPlatforms = nixpkgs.outputs.legacyPackages.x86_64-linux.rustc.meta.platforms;
      targetPlatforms = with nixpkgs.lib; intersectLists systems.flakeExposed rustPlatforms;
    in
    forSystems targetPlatforms (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustPackages = pkgs.rustPackages_1_77;
        rustPlatform = pkgs.makeRustPlatform { inherit (rustPackages) rustc cargo; inherit (pkgs.darwin.apple_sdk_11_0) stdenv; };
        rustc-unwrapped = rustPackages.rustc-unwrapped.override { inherit (rustPackages) rustc cargo; withBundledLLVM = true; };

        vendors = pkgs.symlinkJoin {
          name = "vendors-dir";
          paths = builtins.map (lockFile: rustPlatform.importCargoLock { inherit lockFile; }) [
            (rust + /Cargo.lock)
            (rust + /src/tools/cargo/Cargo.lock)
            (rust + /src/tools/rust-analyzer/Cargo.lock)
            (rust + /compiler/rustc_codegen_cranelift/Cargo.lock)
            (rust + /src/bootstrap/Cargo.lock)
          ];
        };
      in
      {
        # https://github.com/NixOS/nixpkgs/blob/38c01297e7ec11f7b9e3f2cae7d6fcec6cc767ec/pkgs/development/compilers/rust/rustc.nix
        packages.${system} = {
          default = self.packages.${system}.rustc;
          rustc = rustPackages.rustc.override { inherit (self.packages.${system}) rustc-unwrapped; };
          rustc-unwrapped = rustc-unwrapped.overrideAttrs (final: previous:
            {
              src = rust;
              prePatch = ''
                ln -s ${vendors} vendor
                export VERBOSE=1
              '' + previous.prePatch or "";

              configureFlags =
                let
                  prohibitedPrefixes = [ "--release-channel=" "--tools=" "--target=" ];
                  hasNoProhibitedPrefix = x: ! (builtins.any (pref: pkgs.lib.hasPrefix pref x)) prohibitedPrefixes;
                in
                builtins.filter hasNoProhibitedPrefix previous.configureFlags ++ [
                  "--experimental-targets=Xtensa"
                  "--release-channel=nightly"
                  "--enable-extended"
                  "--tools=clippy,cargo,rustfmt"
                  "--enable-lld"
                ];

              nativeBuildInputs = with pkgs; [ ninja zlib curl ] ++ previous.nativeBuildInputs;
              dontUseNinjaBuild = true;
              dontUseNinjaInstall = true;
              dontUseNinjaCheck = true;
            });
        };
      });
}
