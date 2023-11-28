{ lib, stdenv, system, darwin, fetchFromGitHub, fetchurl, zlib, libedit, pkgconf, cryptsetup, zfs, json_c, linux-pam, openssl, pcsclite, libbsd }:

stdenv.mkDerivation rec {
  pname = "pivy";
  version = "v0.11.2";
  srcs = [
    (fetchFromGitHub {
      owner = "arekinath";
      repo = "pivy";
      rev = version;
      hash = "sha256-FEIIZTtFXN+vBz/kVsRIgj1vSJ/m8vcug1mVBLgTbnU=";
    })
    (fetchurl rec {
      version = "9.5p1";
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-8Cbnt5un+1QPdRgq+W3IqPHbOV+SK7yfbKYDZyaGCGs=";
    })
    (fetchurl rec {
      version = "3.8.2";
      url = "mirror://openbsd/LibreSSL/libressl-${version}.tar.gz";
      hash = "sha256-bUuNW7slofgzZjnlbsUIgFLUOpUlZpeoXEzpEyPCWVQ=";
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
      systemCpuName = (lib.systems.parse.mkSystemFromString system).cpu.name;
      arch = if systemCpuName == "aarch64" then "arm64" else systemCpuName;
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
