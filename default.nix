{ lib, stdenv, fetchFromGitHub, fetchurl, fetchpatch, zlib, libedit, ragel, pkgconf, cryptsetup, zfs, json_c, linux-pam, openssl, pcsclite, libbsd }:

stdenv.mkDerivation rec {
  pname = "pivy";
  version = "v0.12.0";
  srcs = [
    (fetchFromGitHub {
      owner = "arekinath";
      repo = "pivy";
      rev = version;
      hash = "sha256-BVUPKAmKdYGWp4/SCPtRqYlMh3grGQ5xnwMffpMbEE4=";
    })
    (fetchurl rec {
      version = "9.9p1";
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-s0P7zb/4fxWxmG5uFdbU/Jp9NgZr5rf7UHCHuo+WbAI=";
    })
    (fetchurl rec {
      version = "3.9.2";
      url = "mirror://openbsd/LibreSSL/libressl-${version}.tar.gz";
      hash = "sha256-ewMdrGSlnrbuMwT3/7ddrTOrjJ0nnIR/ksifuEYGj5c=";
    })
  ];

  sourceRoot = "source";
  postUnpack = ''
    mv openssh-* "$sourceRoot/openssh"
    touch "$sourceRoot/.openssh.extract"
    mv libressl-* "$sourceRoot/libressl"
    touch "$sourceRoot/.libressl.extract"
  '';

  patches = [
    # https://github.com/arekinath/pivy/issues/52
    (fetchpatch {
      url = "https://github.com/arekinath/pivy/commit/482e5d52449a4201deaf5b858158c149755ca0e5.patch";
      hash = "sha256-k9JZkdd++92wDCyy2KbuCR8ue5S7ufqxhPOm0aws9ts=";
    })
  ];

  postPatch = ''
    substituteInPlace Makefile --replace-warn '-o $(binowner) -g $(bingroup) ' '''
  '';

  dontConfigure = true;

  preBuild =
    let
      hostCpuName = (lib.systems.parse.mkSystemFromString stdenv.hostPlatform.system).cpu.name;
      arch = if hostCpuName == "aarch64" then "arm64" else hostCpuName;
    in
    lib.optionals stdenv.isDarwin ''
      makeFlagsArray+=(SYSTEM_CFLAGS="-arch ${arch}" SYSTEM_LDFLAGS="-arch ${arch}")
    '';

  nativeBuildInputs = [ zlib libedit ragel ] ++ lib.optionals stdenv.isLinux [ pkgconf cryptsetup zfs json_c linux-pam ];
  buildInputs = lib.optionals stdenv.isLinux [ openssl pcsclite libbsd ];

  installFlags = [ "DESTDIR=$(out)" "prefix=" ];

  meta = with lib; {
    description = "Tools for using PIV tokens (like Yubikeys) as an SSH agent, for encrypting data at rest, and more";
    homepage = "https://github.com/arekinath/pivy";
    license = licenses.mpl20;
    maintainers = [ maintainers.aiotter ];
    mainProgram = "pivy-tool";
  };
}
