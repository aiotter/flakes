{ lib, stdenv, system, darwin, fetchFromGitHub, fetchurl, zlib, libedit, pkgconf, cryptsetup, zfs, json_c, linux-pam, openssl, pcsclite, libbsd }:

stdenv.mkDerivation rec {
  pname = "pivy";
  version = "v0.10.0";
  srcs = [
    (fetchFromGitHub {
      owner = "arekinath";
      repo = "pivy";
      rev = version;
      hash = "sha256-y82zbgB9HmXxUvmo/h5Emys+6b2FztC/abzp7Cc4i8Q=";
    })
    (fetchurl rec {
      version = "8.9p1";
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-/Ul2VLerFobaxnL7g9+0ukCW6LX/zazNJiOArli+xec=";
    })
    (fetchurl rec {
      version = "3.5.2";
      url = "mirror://openbsd/LibreSSL/libressl-${version}.tar.gz";
      hash = "sha256-Vv6rjiHD+mVJ+LfXURZYuOmFGBYoOKeVMUcyZUrfPl8=";
    })
  ];

  sourceRoot = "source";
  postUnpack = ''
    mv openssh-* "$sourceRoot/openssh"
    touch "$sourceRoot/.openssh.extract"
    mv libressl-* "$sourceRoot/libressl"
    touch "$sourceRoot/.libressl.extract"
  '';

  patchPhase = ''
    substituteInPlace Makefile --replace '-o $(binowner) -g $(bingroup) ' '''
  '';


  dontConfigure = true;

  preBuild =
    let
      arch = (lib.systems.parse.mkSystemFromString system).cpu.name;
    in
    lib.optionals stdenv.isDarwin ''
      makeFlagsArray+=(SYSTEM_CFLAGS="-arch ${arch}" SYSTEM_LDFLAGS="-arch ${arch}")
    '';

  nativeBuildInputs = [ zlib libedit ] ++ lib.optionals stdenv.isLinux [ pkgconf cryptsetup zfs json_c linux-pam ];
  buildInputs = lib.optionals stdenv.isLinux [ openssl pcsclite libbsd ]
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk_11_0; [ frameworks.PCSC ]);

  installFlags = [ "DESTDIR=$(out)" "prefix=" ];

  meta = with lib; {
    description = "Tools for using PIV tokens (like Yubikeys) as an SSH agent, for encrypting data at rest, and more";
    homepage = "https://github.com/arekinath/pivy";
    license = licenses.mpl20;
    maintainers = [ maintainers.aiotter ];
    mainProgram = "pivy-tool";
  };
}
