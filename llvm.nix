# https://github.com/sdobz/rust-esp-nix/blob/master/llvm-xtensa.nix
{ lib
, stdenv
, fetchFromGitHub
, monorepoSrc ? null
, sourceRoot ? null
, rev ? null
, hash ? null
, version ? null
, python3
, cmake
, ninja
}:

let
  src = if monorepoSrc != null then monorepoSrc else
  fetchFromGitHub {
    owner = "espressif";
    repo = "llvm-project";
    inherit rev hash;
  };
  utils = import ./utils.nix { inherit lib; };
in

stdenv.mkDerivation (self: {
  pname = "llvm-xtensa";
  inherit src;

  version =
    if version != null then version
    else utils.llvmVersionFromCMakeLists (self.src + /llvm/CMakeLists.txt);

  sourceRoot = if sourceRoot != null then sourceRoot else "${self.src.name}/llvm";

  buildInputs = [ python3 cmake ninja ];

  # https://gist.github.com/MabezDev/26e175790f84f2f2b0f9bca4e63275d1
  cmakeFlags = [
    # "-DLLVM_ENABLE_PROJECTS=clang;libc;libclc;lld"
    "-DLLVM_ENABLE_PROJECTS=clang;lld"
    "-DLLVM_INSTALL_UTILS=ON"
    "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Xtensa"
    # "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_BUILD_LLVM_DYLIB=ON" # llvm-config needs this
    "-DBUILD_SHARED_LIBS=ON" # llvm-config needs this
  ];

  # llvm-config needs libLLVM-17.dylib instead of libLLVM.dylib
  # https://github.com/llvm/llvm-project/issues/39599
  postInstall =
    let
      majorVersion = lib.versions.major self.version;
    in
    lib.optionalString stdenv.isDarwin "ln -s $out/lib/libLLVM{,-${majorVersion}}.dylib";

  meta = {
    description = "Fork of LLVM with Xtensa specific patches";
    homepage = "https://github.com/espressif/llvm-project";
    license = lib.licenses.asl20;
  };
})
