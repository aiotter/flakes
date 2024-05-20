{ lib
, rustPlatform
, rustPackages
, rustc-unwrapped ? rustPackages.rustc-unwrapped
, rustc ? rustPackages.rustc
, cargo ? rustPackages.cargo
, llvmForEsp32
, rustSrc ? null
, src
, rev ? null
, hash ? null
, fetchFromGitHub
, symlinkJoin
, zlib
, curl
, ldproxy
, espflash
, makeWrapper
, vendor ? false
, stdenv
}:

let
  src' =
    if rustSrc != null then rustSrc else
    if rev == null || hash == null then src else
    fetchFromGitHub {
      owner = "esp-rs";
      repo = "rust";
      inherit rev hash;
    };

  rustc-unwrapped' = rustc-unwrapped.override {
    # Rust v1.77 is required to build
    inherit rustc cargo;
    llvmSharedForTarget = llvmForEsp32;
    llvmShared = llvmForEsp32;
  };

  targets = [
    "xtensa-esp32-espidf"
    "xtensa-esp32-none-elf"
    "xtensa-esp32s2-espidf"
    "xtensa-esp32s2-none-elf"
    "xtensa-esp32s3-espidf"
    "xtensa-esp32s3-none-elf"
    "xtensa-esp8266-none-elf"
  ];

  rust = rustc-unwrapped'.overrideAttrs
    (final: prev:
      {
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/rust/rustc.nix
        src = src';
        pname = "esp-rust";

        NIX_LDFLAGS =
          # Add LLVM libraries from xtensa's fork to rpath
          let
            matched = builtins.match ".*(-rpath .*/lib).*" prev.NIX_LDFLAGS;
            rpath = "-rpath ${llvmForEsp32}/lib";
          in
          if matched == null then "${prev.NIX_LDFLAGS} ${rpath}"
          else builtins.replaceStrings matched [ rpath ] prev.NIX_LDFLAGS;

        prePatch =
          let
            vendors = symlinkJoin {
              name = "vendors-dir";
              paths = builtins.map (lockFile: rustPlatform.importCargoLock { inherit lockFile; }) [
                (src + /Cargo.lock)
                (src + /src/tools/cargo/Cargo.lock)
                (src + /src/tools/rust-analyzer/Cargo.lock)
                (src + /compiler/rustc_codegen_cranelift/Cargo.lock)
                (src + /src/bootstrap/Cargo.lock)
              ];
            };
          in
          lib.optionalString vendor ''
            ln -s ${vendors} vendor
            export VERBOSE=1
            # export RUST_BACKTRACE=1
          '' + prev.prePatch or "";

        configureFlags =
          let
            prefixesToRemove = [
              "--release-channel="
              "--tools="
              "--target="
            ];
            isPrefixed = prefixes: elem: (builtins.any (pref: lib.hasPrefix pref elem)) prefixes;
            removePrefixedFlags = prefixes: builtins.filter (elem: ! isPrefixed prefixes elem);
          in
          removePrefixedFlags prefixesToRemove prev.configureFlags ++ [
            "--experimental-targets=Xtensa"
            "--release-channel=nightly"
            "--enable-extended"
            "--tools=clippy,cargo,src,rust-src,rustfmt,rust-analyzer-proc-macro-srv"
            # "--llvm-root=${llvmForEsp32}"
          ] ++ builtins.map
            (input: with input; "--set=target.${target}.${option}")
            (lib.cartesianProduct {
              target = targets;
              option = [
                "cc=${llvmForEsp32}/bin/clang"
                "cxx=${llvmForEsp32}/bin/clang++"
                "linker=${llvmForEsp32}/bin/clang"
                # "crt-static=${lib.boolToString buildPlatform.isStatic}"
                "llvm-config=${llvmForEsp32}/bin/llvm-config"
              ];
            });

        nativeBuildInputs = [ zlib curl ] ++ prev.nativeBuildInputs;
      });
in
stdenv.mkDerivation {
  pname = "${rust}-wrapper";
  inherit (rust) version;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  passthru = {
    unwrapped = rust;
    inherit targets;
  };

  buildPhase =
    let
      addPath = "--prefix PATH : ${lib.makeBinPath [rust ldproxy espflash]}";
      addLibClang = "--prefix LIBCLANG_PATH : ${lib.makeLibraryPath [llvmForEsp32]}";
    in
    ''
      makeWrapper ${rust}/bin/rustc $out/bin/rustc ${addPath} ${addLibClang}
      makeWrapper ${rust}/bin/cargo $out/bin/cargo ${addPath} ${addLibClang}
    '';

  doCheck = true;
  checkPhase = ''
    $out/bin/rustc -Z unstable-options --print=all-target-specs-json >/dev/null
  '';
}
