{ lib, stdenv, fetchurl, llvmPackages, cmake, zlib }:

llvmPackages.stdenv.mkDerivation rec {
  pname = "lfortran";
  version = "0.17.0";
  src = fetchurl {
    url = "https://lfortran.github.io/tarballs/release/lfortran-${version}.tar.gz";
    hash = "sha256-RAMOJ9HB+F1sNnwPqQHnrXU+jKBLu1jO8WuBAQhbb1M=";
  };

  nativeBuildInputs = [ cmake llvmPackages.llvm.dev ];
  buildInputs = [
    llvmPackages.llvm
    (zlib.override { shared = false; static = true; })
  ];
  cmakeFlags = [
    "-DWITH_LLVM=yes"
    "-DCMAKE_INSTALL_PREFIX=$(out)"
  ];

  meta = with lib; {
    description = "Modern interactive LLVM-based Fortran compiler";
    homepage = "https://lfortran.org";
    license = licenses.bsd3;
    maintainers = [ maintainers.aiotter ];
  };
}
