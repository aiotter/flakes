{
  stdenv,
  fetchFromGitHub,
  meson,
  lua,
  pkg-config,
  glib,
  ninja,
  apple-sdk_15,
}:

stdenv.mkDerivation {
  pname = "tio";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "tio";
    repo = "tio";
    rev = "cce94b9d9280415d34575103b0f7f1d783ad1b0c";
    hash = "sha256-8dcwsWysLZQC9+vG8k1hE05I+nFuS59IIYWhrYg2cZs=";
  };

  nativeBuildInputs = [
    meson
    lua
    pkg-config
    glib
    ninja
  ];

  buildInputs = [ apple-sdk_15 ];
}
