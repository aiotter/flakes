{
  description = "usbutils overlay for macOS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      darwinSystems = with flake-utils.lib.system; [ x86_64-darwin aarch64-darwin ];
    in
    {
      overlays.default = final: prev: {
        usbutils =
          if prev.stdenv.isDarwin
          then self.packages.${prev.system}.default else prev.usbutils;
      };
    } // flake-utils.lib.eachSystem darwinSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "usbutils";
          version = "014";

          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/utils/usb/usbutils/usbutils-${version}.tar.gz";
            hash = "sha256-WTmKsBKIjf4P0S5Ee0XzaAHp17cdmoZfw44vVJr9udA=";
          };

          nativeBuildInputs = with pkgs; [ autoreconfHook autoconf automake pkg-config libtool ];
          buildInputs = with pkgs; [ libusb1 ];

          patches = [
            (pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/Homebrew/formula-patches/9ef20debdfb9995fec347e401f2b5eb7b6c76f07/usbutils/portable.patch";
              hash = "sha256-+kQe5ioKnIVN98xPv1m7sbHl1VteubyjEFPmZRl97Hk=";
            })
          ];

          meta = with pkgs.lib; {
            description = "Tools for working with USB devices, such as lsusb";
            license = licenses.gpl2Plus;
            homepage = "http://www.linux-usb.org/";
            platforms = platforms.darwin;
            mainProgram = "lsusb";
          };
        };
      });
}
